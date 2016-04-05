class EvapotranspirationsController < ApplicationController

  def show
    @map = "path/to/evapotranspiration/map.img"

    render json: { map: @map }
  end

  def index
    et_readings = [
      { date: '2016-01-01', value: 0.001 },
      { date: '2016-01-02', value: 0.003 },
      { date: '2016-01-03', value: 0.007 },
      { date: '2016-01-04', value: 0.005 },
      { date: '2016-01-05', value: 0.004 },
      { date: '2016-01-06', value: 0.010 },
      { date: '2016-01-07', value: 0.011 },
    ]

    render json: et_readings
  end

  def calculate_et
    render json: {
      inputs: params,
      value: Evapotranspiration.new.potential_et
    }
  end
end
