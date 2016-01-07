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
    render json: { degree_days: 23.1 }
  end
end
