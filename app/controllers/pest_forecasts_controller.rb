class PestForecastsController < ApplicationController

  def index
    # inputs: start_date, end_date, pest
    # return: lat, long, value
    values = PestForecast.select(:latitude).select(:longitude).
      select("sum(#{pest}) as total").
      where("date between ? and ?", start_date, end_date).
      group(:latitude, :longitude).
      order(:latitude, :longitude)
    results = values.collect do |v|
      { lat: v.latitude, long: v.longitude * -1, total: v.total.round(2) }
    end
    render json: results
  end

  def custom
    results = []
    grid = WeatherDatum.calculate_all_degree_days_for_date_range('sine', start_date, end_date, t_min, t_max)

    max = 0
    min = grid[Wisconsin::N_LAT, Wisconsin::W_LONG]
    Wisconsin.each_point do |lat, long|
      total = grid[lat, long].round(2)
      results << { lat: lat, long: (long * -1).round(1), total: total }
      if total > max
        max = total
      elsif total < min
        min = total
      end
    end
    render json: { results: results, min: min, max: max }
  end

  def point_details
    # inputs: start_date, end_date, pest, latitude, longitude
    # return: date, value
    forecasts = PestForecast.for_lat_long_date_range(lat, long, start_date,
                                                     end_date)
      .map { |pf| [pf.date, pf.send(pest)] }.to_h
    forecasts.default = 0

    weather = WeatherDatum.where(latitude: lat, longitude: long).
      where("date >= ? and date <= ?", start_date, end_date).
      order(:date).
      collect do |w|
      {
        date: w.date,
        value: forecasts[w.date].round(1),
        avg_temperature: w.avg_temperature.round(1),
        hours_over: w.hours_rh_over_85
      }
    end

    render json: weather
  end

  def custom_point_details
    weather = WeatherDatum.where(latitude: lat, longitude: long).
      where("date >= ? and date <= ?", start_date, end_date).
      order(:date).
      collect do |w|
      {
        date: w.date,
        value: w.degree_days('sine', t_min, t_max).round(1),
        avg_temperature: w.avg_temperature.round(1),
        hours_over: w.hours_rh_over_85
      }
    end

      render json: weather
  end

  private
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
      DegreeDaysCalculator::DEFAULT_BASE
    else
      params[:t_min].to_f
    end
  end

  def t_max
    params[:t_max].blank? ? PestForecast::NO_MAX : params[:t_max].to_f
  end
end
