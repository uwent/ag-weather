class InsolationsController < ApplicationController

  def index
    @maps = ["path/to/map1.img","path/to/map2.img"]

    render json: @maps
  end
end