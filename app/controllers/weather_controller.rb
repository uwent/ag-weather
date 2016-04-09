class WeatherController < ApplicationController

  def index
    weather_data = WeatherDatum.where(latitude: params[:lat],
                                      longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date],
             params[:end_date])
      .order(:date)

    weather_readings = weather_data.collect do |wd|
      { date: wd.date.to_s, 
        min_temp: wd.min_temperature.round(2),
        avg_temp: wd.avg_temperature.round(2),
        max_temp: wd.max_temperature.round(2), 
        pressure: wd.vapor_pressure.round(2)
      }
    end

    render json: weather_readings
  end
end
