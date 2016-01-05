class EvapotranspirationsController < ApplicationController

  def index
    @map = "path/to/evapotranspiration/map.img"

    render json: @map
  end

  def show
    render nothing: true
  end
end
