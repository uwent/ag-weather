class EvapotranspirationsController < ApplicationController

  def show
    @map = "path/to/evapotranspiration/map.img"

    render json: { map: @map }
  end

  def index
    ets = Evapotranspiration.where(latitude: params[:lat],
                                   longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date],
             params[:end_date])
      .order(:date)

    et_readings = ets.collect do |et|
      { date: et.date.to_s, value: et.potential_et.round(2) }
    end

    render json: et_readings
  end

  def calculate_et
    render json: {
      inputs: params,
      value: Evapotranspiration.new.potential_et
    }
  end
end
