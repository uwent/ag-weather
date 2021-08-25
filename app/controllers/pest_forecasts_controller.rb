class PestForecastsController < ApplicationController

  # GET: returns grid of pest data for dates
  # params:
  #   pest (required)
  #   start_date
  #   end_date

  def index
    info = {}
    pest_data = []

    if PestForecast.column_names.include?(pest)
      freezing_data = check_hard_freeze

      forecasts = PestForecast.where("date between ? and ?", start_date, end_date)

      if forecasts.length > 0
        lats = forecasts.pluck(:latitude)
        longs = forecasts.pluck(:longitude)

        info = {
          start_date: start_date,
          end_date: end_date,
          days: (end_date - start_date).to_i,
          lat_range: [lats.min, lats.max],
          long_range: [longs.min, longs.max]
        }

        pest_data = forecasts.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(#{pest}) as total", "count(#{pest}) as count")
        .collect do |point|
          {
            grid_key: "#{point.latitude}:#{point.longitude}",
            lat: point.latitude,
            long: point.longitude * -1,
            total: point.total.round(2),
            avg: (point.total.to_f / point.count).round(2),
            freeze: false
          }
        end.map do |point|
          point[:freeze] = freezing_data[point[:grid_key]] ? true : false
          point
        end

        status = "OK"
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    render json: {
      pest: pest,
      status: status,
      info: info,
      data: pest_data
    }
  end

  # GET: degree-day grid for date range
  # params (if pest):
  #   pest
  #   start_date
  #   end_date
  # params (if computed):
  #   start_date
  #   end_date
  #   base
  #   upper

  def custom
    start_time = Time.current
    status = "OK"
    info = {}
    dds = []
    min = 0
    max = 0

    if pest.present?
      if PestForecast.column_names.include?(pest)
        pest_data = PestForecast.where(date: start_date..end_date)

        if pest_data.size > 0
          dds = pest_data.group(:latitude, :longitude)
          .order(:latitude, :longitude)
          .select(:latitude, :longitude, "sum(#{pest}) as total")
          .collect do |point|
            {
              lat: point.latitude,
              long: point.longitude * -1,
              total: point.total.round(2)
            }
          end

          # info
          lats = dds.map{ |dd| dd[:lat] }.uniq
          longs = dds.map{ |dd| dd[:long] }.uniq
          totals = dds.map{ |dd| dd[:total] }

          lat_range = [lats.min, lats.max]
          long_range = [longs.min, longs.max]
          points = lats.count * longs.count
          min = totals.min
          max = totals.max
        else
          status = "pest not found"
        end
      else
        status = "no data"
      end
    else
      grid = WeatherDatum.calculate_all_degree_days_for_date_range(
        start_date: start_date,
        end_date: end_date,
        base: base,
        upper: upper
      )

      if grid.size > 0
        grid.keys.each do |coordinate|
          dds << {
            lat: coordinate.first,
            long: (coordinate.last * -1).round(1),
            total: grid[coordinate].round(2)
          }
        end

        # info
        lat_range = [grid.keys.first.min, grid.keys.first.max]
        long_range = [grid.keys.last.min, grid.keys.last.max]
        points = grid.length
        min = grid.values.min.round(2)
        max = grid.values.max.round(2)
      else
        status = "no data"
      end
    end

    info = {
      pest: pest,
      start_date: start_date,
      end_date: end_date,
      days: (end_date - start_date).to_i,
      lat_range: lat_range || [],
      long_range: long_range || [],
      grid_points: points || 0,
      min_value: min,
      max_value: max,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: dds
    }

    render json: response
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
    weather = []
    
    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(latitude: lat, longitude: long)
        .where(date: start_date..end_date)
        .order(date: :desc)
        .map { |pf| [pf.date, pf.send(pest)] }.to_h
      forecasts.default = 0

      if forecasts.length > 0
        weather = WeatherDatum.where(latitude: lat, longitude: long)
        .where(date: start_date..end_date)
        .order(:date)
        .collect do |w|
          {
            date: w.date,
            value: forecasts[w.date].round(1),
            cumulative_value: forecasts.select { |k, v| w.date >= k }.values.sum.round(1),
            min_temp: w.min_temperature.round(1),
            max_temp: w.max_temperature.round(1),
            avg_temp: w.avg_temperature.round(1),
            avg_temp_hi_rh: w.hours_rh_over_90.nil? ? w.avg_temperature : w.avg_temp_rh_over_90,
            hours_hi_rh: w.hours_rh_over_90.nil? ? w.hours_rh_over_85 : w.hours_rh_over_90,
            rh_threshold: w.hours_rh_over_90.nil? ? 85 : 90,
          }
        end
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    info = {
      pest: pest,
      lat: lat,
      long: long,
      start_date: start_date,
      end_date: end_date,
      days: (end_date - start_date).to_i,
      data_days: weather.count,
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: weather
    }
    
    render json: response
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
    dds = []

    weather = WeatherDatum.where(latitude: lat, longitude: long)
    .where(date: start_date..end_date)
    .order(:date)

    if weather.size > 0
      dds = weather.collect do |w|
        {
          date: w.date,
          min_temp: w.min_temperature.round(1),
          max_temp: w.max_temperature.round(1),
          avg_temp: w.avg_temperature.round(1),
          dds: w.degree_days(base, upper).round(1),
          cum_dds: build_cumulative_dd(weather, w.date, base, upper).round(1)
        }
      end
    else
      status = "no data"
    end

    info = {
      lat: lat,
      long: long,
      base: base,
      upper: upper,
      start_date: start_date,
      end_date: end_date,
      days: (end_date - start_date).to_i,
      data_days: dds.size,
      compute_time: Time.current - start_time
    }

    if status == "OK" && info[:days] != info[:data_days]
      status = "missing data"
    end

    response = {
      status: status,
      info: info,
      data: dds
    }

    render json: response
  end

  def info
    pf = PestForecast
    cols = (pf.column_names - ["id", "date", "latitude", "longitude", "created_at", "updated_at"]).sort
    response = {
      pest_names: cols,
      date_range: [pf.minimum(:date).to_s, pf.maximum(:date).to_s],
      days: pf.distinct.pluck(:date).count,
      lat_range: [pf.minimum(:latitude), pf.maximum(:latitude)],
      long_range: [pf.minimum(:longitude), pf.maximum(:longitude)]
    }

    render json: response
  end

  private

  def after_november_first
    date_threshold = end_date.year.to_s + "-11-01"
    end_date >= date_threshold.to_date
  end

  def check_hard_freeze
    date_threshold = end_date.year.to_s + "-11-01"

    return {} if !after_november_first
    weather = WeatherDatum.select('latitude, longitude').distinct.
      where("date >= ? and date <= ?", date_threshold, end_date).
      where("min_temperature < ?", -2.22).
      order(:latitude, :longitude).
      collect do |w|
        {
          "#{w.latitude}:#{w.longitude}" => true
        }
    end.inject({}, :merge)
    weather
  end

  def start_date
    params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
  end

  def end_date
    params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
  end

  def lat
    params[:lat].to_f.round(1)
  end

  def long
    params[:long].to_f.round(1).abs
  end

  def pest
    params[:pest].present? ? params[:pest] : ""
  end

  def base
    params[:base].present? ? params[:base].to_f : DegreeDaysCalculator::BASE_F
  end

  def upper
    params[:upper].present? ? params[:upper].to_f : PestForecast::NO_MAX
  end

  def build_cumulative_dd(weather, date, base, upper)
    degree_days = []
    weather.select { |day| date >= day.date }
      .each do |w|
        degree_days << w.degree_days(base, upper)
      end
    degree_days.sum
  end
end
