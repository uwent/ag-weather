class DegreeDaysController < ApplicationController

  def show
    @map = "path/to/degree_day/map.img"

    degree_day_maps = [
      { type: 'alfalfa_weevil', map: @map },
      { type: 'corn_development', map: @map },
      { type: 'corn_stalk_borer', map: @map },
      { type: 'cranberry', map: @map },
      { type: 'euro_corn_borer', map: @map },
      { type: 'potato', map: @map },
      { type: 'seedcorn_maggot', map: @map },
      { type: 'tree_pests', map: @map }
    ]

    render json: degree_day_maps
  end

  # params:
  #    start_date
  #    latitude
  #    longitude
  #    base_temp
  #    upper_temp
  #    method
  def index
    weather = WeatherDatum.where(latitude: params[:lat], longitude: params[:long])
      .order(date: :asc)
    if params[:start_date]
      weather = weather.where('date >= ?', params[:start_date])
    else
      weather = weather.where('date >= ?', Date.current.beginning_of_year)
    end

    base_temp = !params[:base_temp].nil? ? params[:base_temp].to_f : nil
    upper_temp = !params[:upper_temp].nil? ? params[:upper_temp].to_f : nil
    total = 0

    degree_days = []
    if ["sine", "average", "modified"].include?(params[:method])
      degree_days = weather.collect do |w|
        dd = w.degree_days(params[:method], base_temp, upper_temp)
        total += dd
        {date: w.date, value: total.round(0) }
      end
    end

    render json: degree_days
  end

  private
    def start_date
      params[:start_date].nil? ?
        Date.current.beginning_of_year :
        params[:start_date]
    end

    def end_date
      params[:end_date].nil? ? Date.current : params[:end_date]
    end

    def pest
      params[:pest]
    end

    def latitude
      params[:latitude].nil? ? WiMn::S_LAT : params[:latitude]
    end

    def longitude
      params[:longitude].nil? ? WiMn::E_LAT : params[:longitude]
    end
end
