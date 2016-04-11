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

  def index
    weather = WeatherDatum.where(latitude: params[:lat])
      .where(longitude: params[:long])
      .order(date: :asc)
    if params[:start_date]
      weather.where('date >= ?', params[:start_date])
    else
      weather.where('date >= ?', Date.current.beginning_of_year)
    end

    degree_days = []
    total = 0
    degree_days = weather.collect do |w|
      dd = w.degree_days(params[:method], params[:base_temp],
                         params[:upper_temp])
      total += dd
      {date: total}
    end

    render json: degree_days
  end
end
