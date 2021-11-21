class WeatherController < ApplicationController
  # GET: returns insols for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today

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
          min_temp: w.min_temperature&.round(2),
          max_temp: w.max_temperature&.round(2),
          avg_temp: w.avg_temperature&.round(2),
          dew_point: w.dew_point&.round(2),
          pressure: w.vapor_pressure&.round(2),
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: w.avg_temp_rh_over_90&.round(2)
        }
      end
    else
      status = "no data"
    end

    values = data.map { |day| day[:value] }

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date: start_date,
      end_date: end_date,
      days_requested: (end_date - start_date).to_i,
      days_returned: values.count,
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && info[:days_requested] != info[:days_returned]

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        filename = "weather data for #{lat}, #{long} for #{end_date}.csv"
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: create map and return url to it
  def show
    date = begin
      params[:id] ? Date.parse(params[:id]) : default_weather_date
    rescue
      default_weather_date
    end

    image_name = WeatherDatum.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exist?(image_filename)
      url = image_url
    else
      image_name = WeatherDatum.create_image(date)
      url = image_name == "no_data.png" ? "/no_data.png" : image_url
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: {map: url}
    end
  end

  def all_for_date
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    date = begin
      params[:date] ? Date.parse(params[:date]) : default_weather_date
    rescue
      default_weather_date
    end

    weather = WeatherDatum.where(date: date).order(:latitude, :longitude)

    if weather.size > 0
      data = weather.collect do |w|
        {
          lat: w.latitude.round(1),
          long: w.longitude.round(1),
          min_temp: w.min_temperature&.round(2),
          max_temp: w.max_temperature&.round(2),
          avg_temp: w.avg_temperature&.round(2),
          dew_point: w.dew_point&.round(2),
          pressure: w.vapor_pressure&.round(2),
          hours_rh_over_90: w.hours_rh_over_90,
          avg_temp_rh_over_90: w.avg_temp_rh_over_90&.round(2)
        }
      end
      status = "OK"
    else
      status = "no data"
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq

    info = {
      date: date,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      points: lats.size * longs.size,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status: status}.merge(info) unless params[:headers] == "false"
        filename = "weather data grid for #{date}.csv"
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: valid params for api
  def info
    t = WeatherDatum
    response = {
      date_range: [t.minimum(:date).to_s, t.maximum(:date).to_s],
      total_days: t.distinct.pluck(:date).size,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      table_cols: t.column_names
    }
    render json: response
  end

  private

  def default_weather_date
    WeatherDatum.latest_date || Date.yesterday
  end

  def start_date
    params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
  end

  def end_date
    params[:end_date] ? Date.parse(params[:end_date]) : Date.current
  end

  def lat
    params[:lat].to_d.round(1)
  end

  def long
    params[:long].to_d.round(1)
  end
end
