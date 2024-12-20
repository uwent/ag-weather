class WeatherController < ApplicationController
  OPENWEATHER_KEY = ENV["OPENWEATHER_KEY"]
  WEATHERAPI_KEY = ENV["WEATHERAPI_KEY"]

  # GET: returns weather data for lat, long, date range
  # params:
  #   lat - required, decimal latitude
  #   long - required, decimal longitude
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - temperature units, either 'C' (default) or 'F'

  def index
    params.require([:lat, :long])
    parse_date_or_dates || default_date_range
    index_params

    weather = Weather.where(@query).order(:date)
    if weather.exists?
      @data = weather.collect { |w| weather_hash(w) }
    else
      @status = "no data"
    end

    @days_returned = @data.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info.merge({
      units: {
        temp: @units,
        pressure: "kPa",
        rh: "%"
      }
    })

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        @headers = @info unless params[:headers] == "false"
        filename = "weather data (#{@units}) at #{lat}, #{long}.csv"
        send_data(to_csv(@data, @headers), filename:)
      end
    end
  end

  # GET: returns weather grid for date
  # params:
  #   date - default most recent data
  #   lat_range - latitude range, default entire grid
  #   long_range - longitude range, default entire grid
  #   units - temperature units, either 'C' (default) or 'F'

  def grid
    @date = date || default_single_date
    grid_params
    @data = {}

    weather = Weather.where(@query)
    if weather.exists?
      weather.each do |w|
        key = [w.latitude, w.longitude]
        @data[key] = weather_hash(w)
      end
    else
      @status = "no data"
    end

    @info = grid_info.merge({
      units: {
        temp: @units,
        pressure: "kPa",
        rh: "%"
      }
    })

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.collect do |key, value|
          {latitude: key[0], longitude: key[1]}.merge(value)
        end
        @headers = @info unless params[:headers] == "false"
        filename = "weather data grid for #{@date}.csv"
        send_data(to_csv(csv_data, @headers), filename:)
      end
    end
  end

  # GET: returns grid of freezing days for date range
  # Used for VDIFN
  # params:
  #   date or end_date - default yesterday. Use date for single day
  #   start_date - default 1 week ago
  #   lat_range - min,max - default whole grid
  #   long_range - min,max - default whole grid

  def freeze_grid
    parse_date_or_dates || default_one_week
    grid_params
    @units_text = "freezing days"
    @data = {}
    weather = Weather.where(@query)
    if weather.exists?
      @data = weather.grid_summarize.sum(:freezing)
    else
      @status = "no data"
    end
    @info = grid_info
    render json: {info: @info, data: @data}
  end

  # GET: create map and return url to it
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, 'F' or 'C'
  #   scale - optional, 'min,max' for image scalebar
  #   extent - optional, omit or 'wi' for Wisconsin only
  #   stat - optional, summarization statistic, must be sum, min, max, avg

  def map
    parse_date_or_dates || default_single_date
    @col = parse_col
    map_params
    @image_args[:col] = @col

    image_name = Weather.image_name(**@image_args)
    image_type = @start_date ? "cumulative" : "daily"
    image_filename = Weather.image_path(image_name, image_type)

    if File.exist?(image_filename)
      @url = Weather.image_url(image_name, image_type)
      @status = "already exists"
    else
      image_name = Weather.guess_image(**@image_args)
      if image_name
        @url = Weather.image_url(image_name, image_type)
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

  # GET: 5-day forecast from openweather
  # params:
  #   lat (required)
  #   long (required)
  # units:
  #   temp: C
  #   rain: mm

  def forecast
    params.require([:lat, :long])

    start_time = Time.now
    lat = params[:lat]
    lon = params[:long]
    url = "https://api.openweathermap.org/data/2.5/forecast"
    query = {lat:, lon:, units: "imperial", appid: OPENWEATHER_KEY}

    response = HTTParty.get(url, query:)
    forecasts = response["list"]

    if forecasts.nil?
      return render json: {
        status: response["cod"],
        message: response["message"]
      }
    end

    if params[:raw] == "true"
      return render json: response
    end

    days = {}
    forecasts.each do |fc|
      time = Time.at(fc["dt"])
      date = time.to_date
      w = fc["main"].symbolize_keys
      wind = fc["wind"].symbolize_keys
      rain = fc.key?("rain") ? fc["rain"]["3h"] : 0.0
      weather = {
        date:,
        time:,
        temp: [w[:temp_min], w[:temp_max]],
        humidity: w[:humidity],
        wind:,
        rain:
      }
      days[date] ||= []
      days[date] << weather
    end

    days.keys.each do |date|
      fcs = days[date]

      if date > Date.current && fcs.size < 8
        days.delete(date)
        next
      end

      temps = fcs.map { |h| h[:temp] }.flatten
      hums = fcs.map { |h| h[:humidity] }
      wind = fcs.map { |h| h[:wind][:speed] }
      wind_degs = fcs.map { |h| h[:wind][:deg] }
      wind_deg = wind_degs.sort[wind_degs.size / 2] # median

      days[date] = {
        date: date,
        temp: {
          min: temps.min,
          max: temps.max,
          avg: (temps.sum / temps.size).round(2)
        },
        humidity: {
          min: hums.min,
          max: hums.max,
          avg: hums.sum / hums.size
        },
        wind: {
          min: wind.min,
          max: wind.max,
          avg: (wind.sum / wind.size).round(2),
          deg: wind_deg,
          bearing: deg_to_dir(wind_deg)
        },
        rain: fcs.map { |h| h[:rain] }.sum.round(2),
        hours: fcs.size * 3
      }
    end

    # the openweather API is rate limited to 60/min
    sleep(1.05) unless Rails.env.development?

    render json: {
      lat: lat,
      long: long,
      status: "OK",
      units: {
        temp: "F",
        humidity: "%",
        wind: "mph",
        rain: "mm"
      },
      compute_time: Time.now - start_time,
      forecasts: days.values
    }
  end

  # GET: 7-day hourly forecast from National Weather Service
  # params:
  #   lat (required)
  #   long (required)

  def forecast_nws
    params.require([:lat, :long])

    start_time = Time.current
    lat = params[:lat]
    long = params[:long]

    # get grid info
    grid_url = "https://api.weather.gov/points/#{lat},#{long}"
    grid_res = JSON.parse(HTTParty.get(grid_url), symbolize_names: true)
    reject("Unable to get forecast for #{lat}, #{long}: #{grid_res[:detail]}") unless grid_res[:properties]

    # get forecast
    forecast_url = grid_res[:properties][:forecastHourly]
    forecast_res = JSON.parse(HTTParty.get(forecast_url), symbolize_names: true)
    reject("Unable to get forecast for #{lat}, #{long}: #{forecast_res[:detail]}") unless forecast_res[:properties]
    forecasts = forecast_res[:properties][:periods]

    if params[:raw] == "true"
      return render json: forecast_res
    end

    days = {}
    forecasts.each do |fc|
      time = Time.parse(fc[:startTime])
      date = time.to_date
      weather = {
        date:,
        time:,
        hour: time.hour,
        temp: fc[:temperature],
        wind: fc[:windSpeed].to_f,
        wind_dir: fc[:windDirection]
      }
      days[date] ||= []
      days[date] << weather
    end

    render json: {
      lat:,
      long:,
      start_date: days.keys.first,
      end_date: days.keys.last,
      days: days.size,
      compute_time: Time.now - start_time,
      forecasts: days
    }
  end

  # GET: Returns info about weather db

  def info
    render json: get_info(Weather)
  end

  private

  def parse_col
    col = params[:col]&.to_sym
    if col
      reject("Invalid data column: '#{col}'. Must be one of #{Weather.data_cols.join(", ")}") unless Weather.data_cols.include?(col)
    else
      col = Weather.default_col
    end
    col
  end

  def default_date
    WeatherImporter.latest_date || Date.yesterday
  end

  def default_one_week
    @end_date = default_date
    @start_date = @end_date - 1.week
    @dates = @start_date..@end_date
  end

  def valid_units
    @col ||= Weather.default_col
    Weather.valid_units(@col)
  end

  def in_f
    @units == "F"
  end

  # temps in C by default
  def convert_temp(temp)
    return if temp.nil?
    temp = in_f ? UnitConverter.c_to_f(temp) : temp
    temp&.round(2)
  end

  def weather_hash(w)
    {
      date: w.date.to_s,
      min_temp: convert_temp(w.min_temp),
      max_temp: convert_temp(w.max_temp),
      avg_temp: convert_temp(w.avg_temp),
      dew_point: convert_temp(w.dew_point),
      vapor_pressure: w.vapor_pressure&.round(4),
      min_rh: w.min_rh&.round(2),
      max_rh: w.max_rh&.round(2),
      avg_rh: w.avg_rh&.round(2),
      hours_rh_over_90: w.hours_rh_over_90,
      avg_temp_rh_over_90: convert_temp(w.avg_temp_rh_over_90),
      frost: w.frost == 1,
      freezing: w.freezing == 1
    }
  end

  # directional compass bearings
  def bearings
    {
      N: 0,
      NE: 45,
      E: 90,
      SE: 135,
      S: 180,
      SW: 225,
      W: 270,
      NW: 315
    }.freeze
  end

  # convert a degree to the nearest compass bearing, for wind directions
  def deg_to_dir(deg)
    deg = (deg + 22.5) % 360
    bearings.each do |k, v|
      return k.to_s if deg.between?(v, v + 45)
    end
  end
end
