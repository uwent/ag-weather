class InsolationsController < ApplicationController

  def show
    render json: { west_map: "path/to/map1.img", east_map: "path/to/map2.img" }
  end
end