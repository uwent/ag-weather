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

  def info
    # inputs: start_date, end_date, pest, latitude, longitude
    # return: date, value
    values = PestForecast.select(:date).
                  select("pest_forecasts.#{pest} as value").
                  where("date between ? and ?", start_date, end_date).
                  where(latitude: lat).
                  where(longitude: long).
                  order(:date)
    results = values.collect do |v|
      { date: v.date, value: v.value.round(2) }
    end

    render json: results
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
end
