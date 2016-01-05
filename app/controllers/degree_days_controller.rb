class DegreeDaysController < ApplicationController

  def show
    @map = "path/to/degree_day/map.img"

    render json: @map
  end
end