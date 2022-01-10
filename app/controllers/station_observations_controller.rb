class StationObservationsController < ApplicationController
  def index
    station = find_station(params[:name])
    start_date = params[:start_date].blank? ? Date.today.beginning_of_year : Date.parse(params[:start_date])
    end_date = params[:end_date].blank? ? Date.today : Date.parse(params[:end_date])
    # check if null
    readings = (start_date..end_date).map do |date|
      station.aggregate_observation_for_day(date)
    end.compact

    p_cumlative = 0
    readings.each do |reading|
      p_cumlative += reading[:p_days]
      reading[:p_days_cumlative] = p_cumlative.round(2)
    end

    render json: readings
  end

  private

  def find_station(name)
    name.delete!(" ")
    Station.where(name:).first
  end
end
