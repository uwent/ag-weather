class PrecipsController < ApplicationController
  # GET: returns precips for lat, long, date range
  # params:
  #   lat - required, point latitude
  #   long - required, point longitude
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional either "mm" (default) or "in"

  def index
    parse_date_or_dates || default_date_range
    index_params
    cumulative_value = 0
    
    precips = Precip.where(@query)
    if precips.empty?
      @status = "no data"
    else
      @data = precips.collect do |precip|
        value = convert(precip.precip)
        cumulative_value += value
        {
          date: precip.date.to_s,
          value: value.round(5),
          cumulative_value: cumulative_value.round(4)
        }
      end
    end

    @total = cumulative_value
    @values = @data.collect { |day| day[:value] }
    @days_returned = @values.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = @info unless params[:headers] == "false"
        filename = "precip data (#{@units}) for #{lat}, #{long}.csv"
        send_data(to_csv(@data, headers), filename:)
      end
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date or end_date - defaults to most recent data
  #   start_date - optional, provides a sum across dates if given
  #   lat_range - optional, constrain latitudes i.e. '45,50'
  #   long_range - optional, constrain longitudes i.e. '-89,-85'
  #   units - optional, either 'mm' (default) or 'in'

  def grid
    parse_date_or_dates || default_single_date
    grid_params

    precips = Precip.where(@query)
    if precips.exists?
      @days_returned = precips.where(latitude: @lat_range.min, longitude: @long_range.min).size
      @data = precips.grid_summarize.sum(:precip)
      @data.each { |k, v| @data[k] = convert(v) } if @units != "mm"
      @status = "missing days" if @days_returned < @days_requested
    else
      @status = "no data"
    end

    @values = @data.values
    @info = grid_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.map do |key, value|
          {latitude: key[0], longitude: key[1], value:}
        end
        headers = @info unless params[:headers] == "false"
        filename = "precip data grid (#{@units}) for #{@date}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: create map and return url to it

  def map
    parse_date_or_dates || default_single_date
    map_params

    image_name = Precip.image_name(**@image_args)
    image_filename = Precip.image_path(image_name)
    image_url = Precip.image_url(image_name)

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = Precip.guess_image(**@image_args)
      if image_name
        @url = image_url
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

  # GET: Returns info about precips db

  def info
    start_time = Time.current
    t = Precip
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      table_cols: t.column_names,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      value_range: [t.minimum(:precip), t.maximum(:precip)],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - start_time
    }
    render json: response
  end

  private

  def default_date
    PrecipDataImport.latest_date || Date.yesterday
  end

  def valid_units
    Precip.valid_units
  end

  # precips stored in mm
  def convert(val)
    @units == "in" ? UnitConverter.mm_to_in(val) : val
  end
end
