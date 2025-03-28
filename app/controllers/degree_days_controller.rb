class DegreeDaysController < ApplicationController
  # GET: returns weather and computed degree days for point
  # params:
  #   lat - required, decimal latitude
  #   lng - required, decimal longitude
  #   date or end_date - optional, default 1st of year. Use date for single day
  #   start_date - optional, default 1st of year
  #   Must specify one of:
  #     model - name of degree day model column (default dd_50_86)
  #   OR
  #     base - required, default 50F
  #     upper - optional, default none
  #     method - default sine
  #   units - either 'F' (default) or 'C'

  def index
    parse_date_or_dates || default_date_range
    index_params
    parse_model_or_base_upper
    cumulative_value = 0

    weather = Weather.where(@query).order(:date)
    if weather.exists?
      @data = weather.collect do |w|
        dd = w.degree_days(base: @base, upper: @upper, method: @method, in_f:)
        min = convert_temp(w.min_temp)
        max = convert_temp(w.max_temp)
        avg = convert_temp(w.avg_temp)
        cumulative_value += dd
        {
          date: w.date,
          min_temp: min.round(2),
          max_temp: max.round(2),
          avg_temp: avg.round(2),
          value: dd.round(4),
          cumulative_value: cumulative_value.round(3)
        }
      end
    else
      @status = "no data"
    end

    @total = cumulative_value
    @values = @data.map { |day| day[:value] }
    @days_returned = @data.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = @info unless params[:headers] == "false"
        filename = "#{@model_text} degree day data for #{lat}, #{lng}.csv"
        send_data(to_csv(@data, headers), filename:)
      end
    end
  end

  # GET: degree-day grid for date range
  # will either return pre-calculated degree day accumulations or compute new ones
  # params:
  #   Must specify one of:
  #     model - name of degree day model column (default dd_50_86)
  #   OR
  #     base - default 50F, required
  #     upper - default 86F, optional
  #   units - 'F' (default) or 'C' degree days
  #   start_date - default first of year
  #   end_date - default today
  #   lat_range (min,max) - default full extent
  #   lng_range (min,max) - default full extent
  #   compute=true - force computation of a custom degree day model grid (takes at least 25s)

  def grid
    parse_date_or_dates || default_date_range
    grid_params
    parse_model_or_base_upper # after grid_params
    @data = {}

    dds = DegreeDay.where(@query)
    if dds.exists?
      if @model
        @data = dds.grid_summarize.sum(@model)
      elsif @compute
        @status = "calculated new degree day model"
        weather = Weather.where(query)
        @data = Hash.new(0)
        weather.each do |w|
          key = [w.latitude, w.longitude]
          @data[key] += w.degree_days(base: @base, upper: @upper, in_f:)
        end
      else
        @status = "No matching pre-calculated degree-day model found, force with compute=true. Models include #{DegreeDay.data_cols.join(", ")}"
      end
    else
      @status = "no data"
    end

    @data.each { |k, v| @data[k] = convert_dds(v)&.round(4) }
    @values = @data.values
    @info = grid_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.collect do |key, value|
          {latitude: key[0], longitude: key[1], value:}
        end
        headers = @info unless params[:headers] == "false"
        filename = "#{@model_text} degree day grid for #{@start_date} to #{@end_date}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: create map and return url to it
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, 'F' or 'C'
  #   scale - optional, 'min,max' for image scalebar
  #   extent - optional, omit or 'wi' for Wisconsin only
  #   stat - optional, summarization statistic, must be sum, min, max, avg
  #   model - optional, which degree day column to render, default 'dd_50_86'

  def map
    parse_date_or_dates || default_date_range
    map_params
    parse_model
    @image_args[:col] = @model

    image_name = DegreeDay.image_name(**@image_args)
    image_type = "cumulative"
    image_filename = DegreeDay.image_path(image_name, image_type)

    if File.exist?(image_filename)
      @url = DegreeDay.image_url(image_name, image_type)
      @status = "already exists"
    else
      image_name = DegreeDay.guess_image(**@image_args)
      if image_name
        @url = DegreeDay.image_url(image_name, image_type)
        @status = "image created"
      end
    end

    @status ||= "unable to create image, invalid query or no data"

    response = {info: map_info, filename: image_name, url: @url}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.png { render html: @url ? "<img src=#{@url} height=100%>".html_safe : @status }
    end
  end

  # GET: Returns weather and degree day accumulations since Jan 1 of present year
  # params:
  #   lat: latitude, decimal degrees (required)
  #   lng: longitude, decimal degrees (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   models: comma-separated degree day model names from degree_days table - default dd_50_86

  def dd_table
    params.require([:lat, :lng])

    status = "OK"
    total = 0
    data = {}
    weather_data = {}
    dd_data = {}
    dates = start_date..end_date
    @units = units
    models = parse_models
    query = {date: dates, latitude: lat, longitude: lng}

    weather = Weather.where(query).select(:date, :min_temp, :max_temp).order(:date)
    dds = DegreeDay.where(query).order(:date)

    if weather.empty? || dds.empty?
      status = "no data"
    else
      weather.each do |w|
        weather_data[w.date] = {
          min_temp: convert_temp(w.min_temp).round(2),
          max_temp: convert_temp(w.max_temp).round(2)
        }
      end

      models.each do |m|
        total = 0
        dd_data[m] = {}
        dds.each do |dd|
          value = convert_dds(dd.public_send(m)) || 0
          total += value
          dd_data[m][dd.date] = {
            value: value.round(4),
            total: total.round(3)
          }
        end
      end

      # arrange weather and dds by date
      dates.each do |date|
        data[date] = weather_data[date] || {min_temp: nil, max_temp: nil}
        models.each do |m|
          data[date][m] = dd_data[m][date]
        end
      end
    end

    days_requested = dates.count
    days_returned = data.size
    status = "missing days" if status == "OK" && days_requested != days_returned

    info = {
      status:,
      lat:,
      lng:,
      start_date:,
      end_date:,
      days_requested:,
      days_returned:,
      models:,
      units: units_text,
      compute_time: Time.current - @start_time
    }

    response = {info:, data:}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
    end
  end

  # GET: Returns info about degree day data and methods. No params.

  def info
    render json: get_info(DegreeDay)
  end

  private

  def parse_model
    @model = dd_model || DegreeDay.default_col
  end

  def parse_model_or_base_upper
    @base = base
    @upper = upper
    if @upper && @upper < @base
      reject("Upper threshold '#{@upper}' must be lower than base temperature '#{@base}'")
    end
    @units = units
    @method = method
    @compute = params[:compute] == "true"

    if dd_model
      @model = dd_model
    elsif @base
      implied_model = DegreeDay.find_model(@base, @upper, @units)
      @model = if DegreeDay.model_names.include?(implied_model)
        implied_model
      end
    else
      @model = DegreeDay.default_col.to_s
    end

    @base, @upper = DegreeDay.parse_model(@model, @units) if @model
    @model_text = "base #{@base}#{@units}"
    @model_text += ", upper #{@upper}#{@units}" if @upper
  end

  def valid_units
    DegreeDay.valid_units
  end

  def in_f
    @units == "F"
  end

  # temps in C by default
  def convert_temp(temp)
    in_f ? UnitConverter.c_to_f(temp) : temp
  end

  # degree days in F by default
  def convert_dds(dd)
    in_f ? dd : UnitConverter.fdd_to_cdd(dd)
  end

  def units_text(*args)
    in_f ? "Fahrenheit degree days" : "Celsius degree days"
  end

  def default_base
    in_f ? DegreeDaysCalculator::BASE_F : DegreeDaysCalculator::BASE_C
  end

  def base
    params[:base].present? ? parse_float(params[:base]) : default_base
  end

  def upper
    params[:upper].present? ? parse_float(params[:upper]) : nil
  end

  def dd_model
    return unless params[:model].present?
    model_str = sanitize_param_str(params[:model])
    if params[:model] != model_str || !DegreeDay.model_names.include?(model_str)
      reject("Invalid model: '#{params[:model]}'. Must be one of #{DegreeDay.data_cols.join(", ")}")
    end
    model_str
  end

  def valid_methods
    DegreeDaysCalculator::METHODS
  end

  def method
    val = params[:method]&.downcase
    if val
      if valid_methods.include?(val)
        val
      else
        reject("Invalid method '#{val}'. Must be one of #{valid_methods.join(", ")}")
      end
    else
      "sine"
    end
  end

  def valid_models
    DegreeDay.model_names
  end

  # accepts multiple models separated by commas eg "dd_50,dd_50_86"
  def parse_models
    return [DegreeDay.default_col.to_s] unless params[:models].present?
    model_str = sanitize_param_str(params[:models])
    return valid_models if model_str == "all"
    arr = model_str.split(",")
    valid = arr & valid_models
    invalid = arr - valid
    unless invalid.empty?
      reject("Invalid models '#{invalid.join(", ")}'. Valid models include #{valid_models.join(", ")}")
    end
    valid
  end
end
