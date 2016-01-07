class DegreeDaysController < ApplicationController

  def show
    @map = "path/to/degree_day/map.img"

    render json: {
      alfalfa_weevil: @map,
      corn_development: @map,
      corn_stalk_borer: @map,
      cranberry: @map,
      euro_corn_borer: @map,
      potato: @map,
      seedcorn_maggot: @map,
      tree_pest: @map
    }
  end

  def index
    render json: { degree_days: 23.1 }
  end
end