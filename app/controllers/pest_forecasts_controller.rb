class PestForecastsController < ApplicationController

  # GET: returns pest data
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

  def custom
    results = []
    min = 0
    max = 0
    if pest.present?
      results = get_pest_forecast_data
      min = results.map{|result| result[:total] }.min
      max = results.map{|result| result[:total] }.max
    else
      grid = WeatherDatum.calculate_all_degree_days_for_date_range(LandGrid.new, start_date, end_date, 'sine', t_min, t_max)
      grid.keys.each do |coordinate|
        results << { lat: coordinate.first, long: (coordinate.last * -1).round(1), total: grid[coordinate].round(2) }
      end
      min = grid.values.min&.round
      max = grid.values.max&.round
    end
    render json: { results: results, min: min, max: max }
  end

  def point_details
    # inputs: start_date, end_date, pest, latitude, longitude
    # return: date, value
    forecasts = PestForecast.for_lat_long_date_range(lat, long, start_date, end_date)
      .map { |pf| [pf.date, pf.send(pest)] }.to_h
    forecasts.default = 0
    weather = WeatherDatum.where(latitude: lat, longitude: long).
      where("date >= ? and date <= ?", start_date, end_date).
      order(:date).
      collect do |w|
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
    render json: weather
  end

  def custom_point_details
    weather = WeatherDatum.where(latitude: lat, longitude: long).
      where("date >= ? and date <= ?", start_date, end_date).
      order(:date)

    weather_data = weather.collect do |w|
      {
        date: w.date,
        value: w.degree_days('sine', t_min, t_max).round(1),
        cumulative_value: build_cumulative_dd(weather, w.date, t_min, t_max).round(1),
        min_temp: w.min_temperature.round(1),
        max_temp: w.max_temperature.round(1),
        avg_temp: w.avg_temperature.round(1),
        t_min: t_min,
        t_max: t_max
      }
    end
    render json: weather_data
  end


  private

  def get_pest_forecast_data
    # PestForecast.select(:latitude).select(:longitude).
    #   select("sum(#{pest}) as total").
    #   select("count(#{pest}) as count").
    #   where("date between ? and ?", start_date, end_date).
    #   group(:latitude, :longitude).
    #   order(:latitude, :longitude).
    #   collect {
    #     |v| {
    #       lat: v.latitude,
    #       long: v.longitude * -1,
    #       total: v.total.round(2),
    #       days: v.count,
    #       avg: (v.total.to_f / v.count).round(2),
    #       after_november_first: after_november_first,
    #       freeze: false,
    #       grid_key: "#{v.latitude}:#{v.longitude}"
    #     }
    #   }
    PestForecast.where("date between ? and ?", start_date, end_date)
    .select(:latitude, :longitude, "sum(#{pest}) as total", "count(#{pest}) as count")
    .group(:latitude, :longitude)
    .order(:latitude, :longitude)
    .collect do |point|
      {
        grid_key: "#{point.latitude}:#{point.longitude}",
        lat: point.latitude,
        long: point.longitude * -1,
        total: point.total.round(2),
        avg: (point.total.to_f / point.count).round(2),
        freeze: false
      }
    end
  end

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
    params[:start_date].blank? ? 7.days.ago.to_date : Date.parse(params[:start_date])
  end

  def end_date
    params[:end_date].blank? ? Date.current : Date.parse(params[:end_date])
  end

  def lat
    params[:latitude].to_f.round(1)
  end

  def long
    params[:longitude].to_f.round(1).abs
  end

  def pest
    params[:pest]
  end

  def t_min
    if params[:t_min].blank?
      DegreeDaysCalculator::BASE_F
    else
      params[:t_min].to_f
    end
  end

  def t_max
    params[:t_max].blank? ? PestForecast::NO_MAX : params[:t_max].to_f
  end

  def build_cumulative_dd(weatherList, date, t_min, t_max)
    degree_days = []
    weatherList.select { |d| date >= d.date }
      .each do |w|
        degree_days << w.degree_days('sine', t_min, t_max)
      end
    degree_days.sum
  end
end
