class WeatherController < ApplicationController
  OW_KEY = ENV["OPENWEATHER_API_KEY"]

  # GET: returns weather data for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today
  #   units - default C

  def index
    start_time = Time.current
    status = "OK"
    data = []

    weather = WeatherDatum.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    if weather.size > 0
      data = weather.collect do |w|
        {
          date: w.date.to_s,
          min_temp: convert(w.min_temperature),
          max_temp: convert(w.max_temperature),
          avg_temp: convert(w.avg_temperature),
          dew_point: convert(w.dew_point),
          pressure: w.vapor_pressure,
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: convert(w.avg_temp_rh_over_90)
        }
      end
    else
      status = "no data"
    end

    values = data.map { |day| day[:value] }

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      units:,
      days_requested: (end_date - start_date).to_i,
      days_returned: values.count,
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && info[:days_requested] != info[:days_returned]

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
  def show
    start_time = Time.current
    @date = [date_from_id, default_date].min
    @units = units

    image_name = WeatherDatum.image_name(@date, @units)
    image_filename = File.join(ImageCreator.file_dir, image_name)

    if File.exist?(image_filename)
      url = File.join(ImageCreator.url_path, image_name)
    else
      image_name = WeatherDatum.create_image(@date, units: @units)
      url = image_name == "no_data.png" ? "/no_data.png" : File.join(ImageCreator.url_path, image_name)
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: {
        params: {
          date: @date,
          units: @units
        },
        compute_time: Time.current - start_time,
        map: url
      }
    end
  end

  # GET: returns weather grid for date
  # params:
  #   date (required)
  #   units - default C
  def all_for_date
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    @date = date

    weather = WeatherDatum.where(date: @date).order(:latitude, :longitude)

    if weather.size > 0
      data = weather.collect do |w|
        {
          lat: w.latitude.round(1),
          long: w.longitude.round(1),
          min_temp: convert(w.min_temperature),
          max_temp: convert(w.max_temperature),
          avg_temp: convert(w.avg_temperature),
          dew_point: convert(w.dew_point),
          pressure: w.vapor_pressure,
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: convert(w.avg_temp_rh_over_90)
        }
      end
      status = "OK"
    else
      status = "no data"
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq

    info = {
      date: @date,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      points: lats.size * longs.size,
      units:,
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
    lat = params[:lat]
    lon = params[:long]
    url = "https://api.openweathermap.org/data/2.5/forecast"
    query = {lat:, lon:, units: "imperial", appid: OW_KEY}

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

    sleep(1) unless Rails.env.development? # the openweather API is rate limited to 60/min

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
      forecasts: days.values
    }
  end

  # GET: valid params for api
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
    if units == "F"
      UnitConverter.c_to_f(temp)
    else
      temp
    end
  end

  def bearings
    {
      N: 0,
      NNE: 22.5,
      NE: 45,
      ENE: 67.5,
      E: 90,
      ESE: 112.5,
      SE: 135,
      SSE: 157.5,
      S: 180,
      SSW: 202.5,
      SW: 225,
      WSW: 247.5,
      W: 270,
      WNW: 292.5,
      NW: 315,
      NNW: 337.5
    }.freeze
  end

  def deg_to_dir(deg)
    deg = (deg - 180 + 11.25) % 360
    bearings.each do |k, v|
      return k.to_s if deg.between?(v, v + 22.5)
    end
  end
end
