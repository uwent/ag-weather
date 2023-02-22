class WeatherController < ApplicationController
  OPENWEATHER_KEY = ENV["OPENWEATHER_KEY"]
  WEATHERAPI_KEY = ENV["WEATHERAPI_KEY"]

  # GET: returns weather data for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today
  #   units - default C

  def index
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    data = []

    weather = WeatherDatum.where(
      date: start_date..end_date,
      latitude: lat,
      longitude: long
    ).order(:date)

    if weather.exists?
      data = weather.collect do |w|
        {
          date: w.date.to_s,
          min_temp: convert(w.min_temp),
          max_temp: convert(w.max_temp),
          avg_temp: convert(w.avg_temp),
          dew_point: convert(w.dew_point),
          vapor_pressure: w.vapor_pressure,
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: convert(w.avg_temp_rh_over_90)
        }
      end
    else
      status = "no data"
    end

    values = data.map { |day| day[:value] }
    days_requested = (start_date..end_date).count
    days_returned = values.count

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      units: {
        temp: units,
        pressure: "kPa"
      },
      days_requested:,
      days_returned:,
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && days_requested != days_returned

    response = {
      status:,
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        filename = "weather data for #{lat}, #{long} for #{end_date}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: create map and return url to it
  def map
    start_time = Time.current
    @date = [date, default_date].min
    @units = units

    image_name = WeatherDatum.image_name(@date, @units)
    image_filename = File.join(ImageCreator.file_dir, image_name)

    if File.exist?(image_filename)
      @url = File.join(ImageCreator.url_path, image_name)
      @status = "already exists"
    else
      image_name = WeatherDatum.create_image(@date, units: @units)
      if image_name
        @url = File.join(ImageCreator.url_path, image_name)
        @status = "image created"
      else
        @status = "no data"
      end
    end

    if request.format.png?
      render html: "<img src=#{@url} height=100%>".html_safe
    else
      render json: {
        info: {
          status: @status,
          date: @date,
          mapped_value: "avg_temp",
          units: @units,
          compute_time: Time.current - start_time
        },
        map: @url
      }
    end
  end

  # GET: returns weather grid for date
  # params:
  #   date - default most recent data
  #   units - default C
  #   lat_range - latitude range, default entire grid
  #   long_range - longitude range, default entire grid

  def grid
    start_time = Time.current
    status = "OK"
    info = {}
    data = []
    @date = date

    weather = WeatherDatum.where(
      date: @date,
      latitude: lat_range,
      longitude: long_range
    )

    if weather.exists?
      data = weather.collect do |w|
        {
          latitude: w.latitude,
          longitude: w.longitude,
          min_temp: convert(w.min_temp).round(3),
          max_temp: convert(w.max_temp).round(3),
          avg_temp: convert(w.avg_temp).round(3),
          dew_point: convert(w.dew_point).round(3),
          vapor_pressure: w.vapor_pressure.round(5),
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: convert(w.avg_temp_rh_over_90)&.round(3),
          frost: w.frost == 1,
          freezing: w.freezing == 1
        }
      end
      status = "OK"
    else
      status = "no data"
    end

    info = {
      date: @date,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      units: {
        temp: units,
        pressure: "kPa"
      },
      compute_time: Time.current - start_time
    }

    response = {
      status:,
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status:}.merge(info) unless params[:headers] == "false"
        filename = "weather data grid for #{@date}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
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

    grid_url = "https://api.weather.gov/points/#{lat},#{long}"
    grid_res = JSON.parse(HTTParty.get(grid_url), symbolize_names: true)

    forecast_url = grid_res[:properties][:forecastHourly]
    forecast_res = JSON.parse(HTTParty.get(forecast_url), symbolize_names: true)
    forecasts = forecast_res[:properties][:periods]

    if forecasts.nil?
      return render json: {
        status: 404,
        message: "Unable to retrieve forecast."
      }
    end

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

  # GET: returns grid of frost and freezing counts for date range
  # Used for VDIFN
  # params:
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   lat_range - min,max - default whole grid
  #   long_range - min,max - default whole grid

  def freeze_grid
    start_time = Time.current
    status = "OK"
    info = {}
    data = {}

    weather = WeatherDatum.where(
      date: start_date..end_date,
      latitude: lat_range,
      longitude: long_range
    )

    if weather.exists?
      data = weather.grid_summarize.sum(:freezing)
    else
      status = "no data"
    end

    info = {
      status:,
      start_date:,
      end_date:,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      compute_time: Time.current - start_time
    }

    response = {
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      # format.csv do
      #   headers = info unless params[:headers] == "false"
      #   filename = "pest data grid for #{pest}.csv"
      #   send_data(to_csv(response[:data], headers), filename:)
      # end
    end
  end

  # GET: Returns info about weather db

  def info
    start_time = Time.current
    t = WeatherDatum
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      table_cols: t.column_names,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - start_time
    }
    render json: response
  end

  private

  def units
    valid_units = WeatherDatum::UNITS
    if params[:units].present?
      unit = params[:units].upcase
      if valid_units.include?(unit)
        unit
      else
        raise ActionController::BadRequest.new("Invalid unit '#{params[:units]}'. Must be one of #{valid_units.join(", ")}.")
      end
    else
      valid_units[0]
    end
  end

  # weather temps are in C
  def convert(temp)
    return if temp.nil?
    if units == "F"
      UnitConverter.c_to_f(temp)
    else
      temp
    end
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
