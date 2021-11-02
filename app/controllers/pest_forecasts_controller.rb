class PestForecastsController < ApplicationController

  # GET: returns grid of pest data for dates
  # params:
  #   pest (required)
  #   start_date
  #   end_date
  #   lat_range - min,max
  #   long_range - min,max

  def index
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    if PestForecast.column_names.include?(pest)
      freezing_data = check_hard_freeze
      forecasts = PestForecast.where(date: start_date..end_date)
      .where(latitude: lat_range, longitude: long_range)

      if forecasts.size > 0
        days_returned = forecasts.distinct.pluck(:date).size
        data = forecasts.select(:latitude, :longitude, "sum(#{pest}) as total", "count(#{pest}) as count")
        .group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .collect do |point|
          {
            grid_key: "#{point.latitude}:#{point.longitude}",
            lat: point.latitude.to_f.round(1),
            long: point.longitude.to_f.round(1),
            total: point.total.round(2),
            avg: (point.total.to_f / point.count).round(2),
            freeze: false
          }
        end.map do |point|
          point[:freeze] = freezing_data[point[:grid_key]] ? true : false
          point
        end.each { |h| h.delete(:grid_key) }
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq
    values = data.map { |d| d[:total] }
    data = data.each { |h| h.delete(:count) }
    days_requested = (end_date - start_date).to_i
    days_returned ||= 0

    status = "missing data" if status == "OK" && days_requested != days_returned

    info = {
      pest: pest,
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      grid_points: lats.count * longs.count || 0,
      min_value: values.min,
      max_value: values.max,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        filename = "pest data grid for #{pest}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: degree-day grid for date range
  # params (if pest):
  #   pest (required) - column name from pest_forecasts
  #   start_date - default 1st of year
  #   end_date - default today
  #   lat_range - min,max
  #   long_range - min,max
  # params (computed from weather if no pest given):
  #   start_date - default first of year
  #   end_date - default today
  #   base - default 50F
  #   upper - default 86F
  #   lat_range (min,max) - default full extent
  #   long_range (min,max) - default full extent

  def custom
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    if pest
      if PestForecast.column_names.include?(pest)
        pest_data = PestForecast.where(date: start_date..end_date)
        .where(latitude: lat_range, longitude: long_range)

        if pest_data.size > 0
          days_returned = pest_data.distinct.pluck(:date).size
          data = pest_data.group(:latitude, :longitude)
          .order(:latitude, :longitude)
          .select(:latitude, :longitude, "sum(#{pest}) as total")
          .collect do |point|
            {
              lat: point.latitude.to_f.round(1),
              long: point.longitude.to_f.round(1),
              total: point.total.round(2)
            }
          end
        else
          status = "pest not found"
        end
      else
        status = "no data"
      end
    else
      weather_info = {
        base_temp: base,
        upper_temp: upper,
        units: "Fahrenheit degree days"
      }
      weather = WeatherDatum.where(date: start_date..end_date)
      .where(latitude: lat_range, longitude: long_range)

      if weather.size > 0
        days_returned = weather.distinct.pluck(:date).size
        grid = weather.each_with_object(Hash.new(0)) do |w, h|
          coord = [w.latitude.to_f, w.longitude.to_f]
          if h[coord].nil?
            h[coord] = w.degree_days(base, upper)
          else
            h[coord] += w.degree_days(base, upper)
          end
          h
        end
        grid.keys.each do |coord|
          data << {
            lat: coord.first,
            long: coord.last,
            total: grid[coord].round(2)
          }
        end
      else
        status = "no data"
      end
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq
    values = data.map { |d| d[:total] }
    days_requested = (end_date - start_date).to_i
    days_returned ||= 0

    status = "missing data" if status == "OK" && days_requested != days_returned

    info = {
      pest: pest || "generic",
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      grid_points: lats.count * longs.count || 0 }
    .merge(weather_info ||= {})
    .merge({
      min_value: values.min,
      max_value: values.max,
      compute_time: Time.current - start_time
      })

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        if pest
          filename = "#{pest} data grid for #{start_date.to_s} to #{end_date.to_s}.csv"
        else
          filename = "degree day grid for #{start_date.to_s} to #{end_date.to_s}.csv"
        end
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: returns pest data for dates at lat/long point
  # params:
  #   pest (required)
  #   lat (required)
  #   long (required)
  #   start_date
  #   end_date

  def point_details
    start_time = Time.current
    status = "OK"
    info = {}
    data = []
    
    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(latitude: lat, longitude: long)
        .where(date: start_date..end_date)
        .order(date: :desc)
        .map { |pf| [pf.date, pf.send(pest)] }.to_h
      forecasts.default = 0

      if forecasts.size > 0
        data = WeatherDatum.where(latitude: lat, longitude: long)
        .where(date: start_date..end_date)
        .order(:date)
        .collect do |w|
          {
            date: w.date,
            min_temp: w.min_temperature.round(1),
            max_temp: w.max_temperature.round(1),
            avg_temp: w.avg_temperature.round(1),
            avg_temp_hi_rh: w.avg_temp_rh_over_90,
            hours_hi_rh: w.hours_rh_over_90,
            value: forecasts[w.date].round(1),
            cumulative_value: forecasts.select { |k, v| w.date >= k }.values.sum.round(1)
          }
        end
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    days_requested = (end_date - start_date).to_i
    days_returned = data.size

    status = "missing data" if status == "OK" && days_requested != days_returned ||= 0

    info = {
      pest: pest,
      lat: lat,
      long: long,
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: data
    }
    
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        filename = "point details for #{pest} at #{lat}, #{long}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: returns degree day data for dates at lat/long point
  # params:
  #   lat (required) - degrees north
  #   long (required) - positive degrees west
  #   base - degrees F
  #   upper - degrees F
  #   start_date - default 1st of year
  #   end_date - default today

  def custom_point_details
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    weather = WeatherDatum.where(latitude: lat, longitude: long)
    .where(date: start_date..end_date)
    .order(:date)

    if weather.size > 0
      days_returned = weather.distinct.pluck(:date).size
      data = weather.collect do |w|
        {
          date: w.date,
          min_temp: w.min_temperature.round(1),
          max_temp: w.max_temperature.round(1),
          avg_temp: w.avg_temperature.round(1),
          value: w.degree_days(base, upper).round(1),
          cumulative_value: build_cumulative_dd(weather, w.date, base, upper).round(1)
        }
      end
    else
      status = "no data"
    end

    days_requested = (end_date - start_date).to_i
    days_returned = data.size

    status = "missing data" if status == "OK" && days_requested != days_returned ||= 0

    info = {
      lat: lat,
      long: long,
      base_temp: base,
      upper_temp: upper,
      units: "Fahrenheit degree days",
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        filename = "degree day data for #{lat}, #{long}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  def info
    pf = PestForecast
    cols = (pf.column_names - ["id", "date", "latitude", "longitude", "created_at", "updated_at"]).sort
    response = {
      pest_names: cols,
      date_range: [pf.minimum(:date).to_s, pf.maximum(:date).to_s],
      total_days: pf.distinct.pluck(:date).count,
      lat_range: [pf.minimum(:latitude), pf.maximum(:latitude)],
      long_range: [pf.minimum(:longitude), pf.maximum(:longitude)]
    }

    render json: response
  end

  private

  def check_hard_freeze
    nov_1 = Date.new(end_date.year, 11, 1)

    return {} if end_date < nov_1
    weather = WeatherDatum.select(:latitude, :longitude)
      .distinct
      .where(date: nov_1..end_date)
      .where("min_temperature < ?", -2.22)
      .order(:latitude, :longitude)
      .collect { |w| { "#{w.latitude}:#{w.longitude}" => true } }
      .inject({}, :merge)
    weather
  end

  def build_cumulative_dd(weather, date, base, upper)
    degree_days = []
    weather.select { |day| date >= day.date }
      .each do |w|
        degree_days << w.degree_days(base, upper)
      end
    degree_days.sum
  end

  def start_date
    begin
      params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
    rescue
      Date.current.beginning_of_year
    end
  end

  def end_date
    begin
      params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
    rescue
      Date.current
    end
  end

  def lat
    params[:lat].to_f.round(1)
  end

  def long
    params[:long].to_f.round(1)
  end

  def lat_range
    begin
      params[:lat_range] ? params[:lat_range].split(",").inject { |s,e| s.to_f.round(1)..e.to_f.round(1) } : LandExtent.latitudes
    rescue
      LandExtent.latitudes
    end
  end

  def long_range
    begin
      params[:long_range] ? params[:long_range].split(",").inject { |s,e| s.to_f.round(1)..e.to_f.round(1) } : LandExtent.longitudes
    rescue
      LandExtent.longitudes
    end
  end

  def pest
    params[:pest]
  end

  def base
    params[:base].present? ? params[:base].to_f : DegreeDaysCalculator::BASE_F
  end

  def upper
    params[:upper].present? ? params[:upper].to_f : PestForecast::NO_MAX
  end

end
