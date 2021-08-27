class WeatherController < ApplicationController

  def index
    weather = WeatherDatum.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    data = weather.collect do |w|
      {
        date: w.date.to_s, 
        min_temp: w.min_temperature.round(2),
        avg_temp: w.avg_temperature.round(2),
        max_temp: w.max_temperature.round(2), 
        pressure: w.vapor_pressure.round(2)
      }
    end

    respond_to do |format|
      format.html { render json: data, content_type: "application/json; charset=utf-8"}
      format.json { render json: data }
      format.csv do
        filename = "weather data for #{lat}, #{long} for #{end_date}.csv"
        send_data helpers.to_csv(data), filename: filename
      end
    end
  end
end

private

def start_date
  params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
end

def end_date
  params[:end_date] ? Date.parse(params[:end_date]) : Date.current
end

def lat
  params[:lat]
end

def long
  params[:long]
end