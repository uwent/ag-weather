class ApplicationController < ActionController::Base
  before_action { @start_time = Time.now }

  rescue_from ActionController::ParameterMissing,
    ActionController::RoutingError,
    ActionController::BadRequest do |message|
    render json: {message:}, status: :bad_request
  end

  def reject(message = "bad request")
    raise ActionController::BadRequest.new(message)
  end

  def index
  end

  private

  def sanitize_param_str(raw)
    return unless raw
    raw.to_s.downcase.gsub(/[^a-z0-9_,\.]/, '')
  end

  def to_csv(data, headers = nil)
    CSV.generate do |csv|
      if headers
        headers.each { |h| csv << [h[0], h[1]] }
        csv << []
      end
      csv << data.first.keys
      data.each { |h| csv << h.values }
    rescue
    end
  end

  def log_prefix(level = 0)
    "#{name}##{caller_locations[level].label} :: "
  end

  # for controller #info endpoints
  def get_info(t)
    min_date = t.minimum(:date)
    max_date = t.maximum(:date)
    all_dates = (min_date..max_date).to_a
    actual_dates = t.dates
    {
      data_cols: t.data_cols,
      lat_range: t.lat_range,
      long_range: t.long_range,
      date_range: t.date_range,
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - @start_time
    }
  rescue
    {message: "error"}
  end

  ## PARSE PARAMS ##

  def parse_number(str)
    /^\d+$/.match?(str) ? str.to_i : nil
  end

  # parse a numeric param from a string (truncated at 10 characters)
  # resultant number is rounded to n digits
  def parse_float(str, digits: nil)
    str = str.to_s[0..9]
    return unless /^-?(?:\d+(?:\.\d+)?|\.\d+)$/.match?(str)
    digits ? str.to_f.round(digits) : str.to_f
  end

  def date
    parse_date(params[:date])
  end

  def start_date(default = default_date.beginning_of_year)
    parse_date(params[:start_date], default:)
  end

  def end_date
    parse_date(params[:end_date], default: default_date)
  end

  def default_date
    DataImport.maximum(:date) || DataImport.latest_date
  end

  def default_single_date
    @date = default_date
  end

  def default_date_range
    @end_date = default_date
    @start_date = @end_date.beginning_of_year
    @dates = @start_date..@end_date
  end

  def parse_date(date, default: nil)
    if date
      begin
        Date.parse(date)
      rescue
        reject("Invalid date '#{date}'")
      end
    else
      default
    end
  end

  def parse_date_or_dates
    if params[:start_date] || params[:end_date]
      @end_date = params[:date] ? date : end_date
      @end_date = [@end_date, default_date].min if default_date
      @start_date = start_date(@end_date.beginning_of_year)
      if @start_date >= @end_date
        @date = @end_date
        @start_date = @end_date = nil
      else
        @dates = @start_date..@end_date
      end
    elsif params[:date]
      @date = date
    else
      return false
    end
    true
  end

  def lat
    check_lat(parse_float(params[:lat], digits: 1))
  end

  def long
    check_long(parse_float(params[:long], digits: 1))
  end

  def check_lat(val)
    val.in?(LandExtent.lat_range) ? val : reject("Invalid latitude '#{val}'. Must be in range #{LandExtent.lat_range}")
  end

  def check_long(val)
    val.in?(LandExtent.long_range) ? val : reject("Invalid longitude '#{val}'. Must be in range #{LandExtent.long_range}")
  end

  def lat_range
    param = params[:lat_range]
    range = LandExtent.lat_range
    if param.present?
      coords = parse_coords(param)
      coords.in?(range) ? coords : reject("Invalid latitude range '#{param}'. Must be formatted as e.g. 45.0,50.5 and in range #{range}")
    else
      range
    end
  end

  def long_range
    param = params[:long_range]
    range = LandExtent.long_range
    if param.present?
      coords = parse_coords(param)
      coords.in?(range) ? coords : reject("Invalid longitude range '#{param}'. Must be formatted as e.g. -89.0,-85.5 and in range #{range}")
    else
      range
    end
  end

  def parse_coords(str)
    return unless str.present?
    split = str.split(",")
    return unless split.size >= 2
    arr = [split[0].to_f, split[1].to_f].sort
    arr[0]..arr[1]
  rescue
    nil
  end

  def parse_coord(param, default)
    parse_float(param, digits: 1) || default
  end

  # scale should be given as 'min,max' or separate scale_min, scale_max params
  def scale
    if params[:scale]
      begin
        s = params[:scale].split(",").map(&:to_f).sort
        reject("Must provide two comma-separated values for scale params") if s.size != 2
        s
      rescue
        nil
      end
    else
      s = [scale_min, scale_max]
      (s == [nil, nil]) ? nil : s
    end
  end

  def scale_min
    parse_float(params[:scale_min])
  end

  def scale_max
    parse_float(params[:scale_max])
  end

  def stat
    s = params[:stat]&.to_sym
    return if s.nil?
    valid_stats = [:avg, :min, :max, :sum]
    if valid_stats.include?(s.to_sym)
      @stat = s
    else
      reject("Invalid statistic '#{s}'. Must be one of #{valid_stats.join(", ")}")
    end
  end

  # find the matching unit case insensitive then return the correct units
  def units
    if params[:units]
      unit = params[:units]&.downcase
      i = valid_units.map(&:downcase).find_index(unit)
      if i
        valid_units[i]
      else
        reject("Invalid unit '#{unit}'. Must be one of #{valid_units.join(", ")}")
      end
    else
      valid_units[0]
    end
  end

  def units_text
    @units.to_s
  end

  def extent
    ext = params[:extent]
    if ext
      if ext&.downcase == "wi"
        "wi"
      else
        reject("Invalid extent '#{ext}'. Must be 'wi' or blank for all")
      end
    end
  end

  ## SHARED METHODS ##

  def index_params
    params.require([:lat, :long])
    @days_requested = @dates&.count || 1
    @lat = lat.to_f
    @long = long.to_f
    @units = units
    @units_text = units_text
    @query = {date: @dates || @date, latitude: @lat, longitude: @long}
    @data = []
  end

  def index_info
    {
      status: @status || "OK",
      lat: @lat,
      long: @long,
      date: @date,
      start_date: @start_date,
      end_date: @end_date,
      days_requested: @days_requested,
      days_returned: @days_returned,
      base: @base,
      upper: @upper,
      method: @method,
      pest: @pest,
      units: @units_text,
      min_value: @values&.min,
      max_value: @values&.max,
      total: @total&.round(4),
      compute_time: Time.current - @start_time
    }.compact
  end

  def grid_params
    @lat_range = lat_range
    @long_range = long_range
    @days_requested = @dates&.count || 1
    @units = units
    @units_text = units_text
    @stat = stat
    @query = {date: @dates || @date, latitude: @lat_range, longitude: @long_range}
    @data = {}
  end

  def grid_info
    {
      status: @status || "OK",
      date: @date,
      start_date: @start_date,
      end_date: @end_date,
      days_requested: @days_requested,
      lat_range: "#{@lat_range&.min},#{@lat_range&.max}",
      long_range: "#{@long_range&.min},#{@long_range&.max}",
      grid_points: @data&.size,
      model: @model_text,
      pest: @pest,
      units: @units_text,
      stat: @stat,
      min_value: @values&.min,
      max_value: @values&.max,
      compute_time: Time.current - @start_time
    }.compact
  end

  def map_params
    @units = units
    @scale = scale
    @extent = extent
    @stat = stat
    @image_args = {
      date: @date,
      start_date: @start_date,
      end_date: @end_date,
      units: @units,
      scale: @scale,
      extent: @extent,
      stat: @stat
    }.compact
  end

  def map_info
    {
      status: @status || "OK",
      args: @image_args,
      compute_time: Time.current - @start_time
    }.compact
  end
end
