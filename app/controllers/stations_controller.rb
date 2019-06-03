class StationsController < ApplicationController
  def index
    stations = Station.all.map do |station|
      { name: station.titleized_name,
        lat: station.latitude,
        long: station.longitude
      }
    end
    render json: stations
  end
end
