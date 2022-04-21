class WeatherController < ApplicationController
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
end
