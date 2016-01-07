class EvapotranspirationsController < ApplicationController

  def show
    @map = "path/to/evapotranspiration/map.img"

    render json: @map
  end

  def index
    render nothing: true
  end
end
