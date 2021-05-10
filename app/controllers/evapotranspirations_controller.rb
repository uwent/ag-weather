class EvapotranspirationsController < ApplicationController
  def show
    date = begin
             Date.parse(params[:id])
           rescue ArgumentError
             Date.yesterday
           end
    
    image_name = Evapotranspiration.create_image(date)
    render json: {
      map: File.join(ImageCreator.url_path, image_name)
    }
  end

  def index
    ets = Evapotranspiration.where(latitude: params[:lat], longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date], params[:end_date])
      .order(:date)

    et_readings = ets.collect do |et|
      {
        date: et.date.to_s,
        value: et.potential_et.round(3)
      }
    end

    render json: et_readings
  end

  def all_for_date
    date = begin
             Date.parse(params[:date])
           rescue ArgumentError
             Date.yesterday
           end
    ets = Evapotranspiration.where("date = ?", date).order(:latitude, :longitude)

    et_location_readings = ets.collect do |et|
      {
        lat: et.latitude.round(1),
        long: et.longitude.round(1),
        value: et.potential_et.round(3)
      }
    end
    render json: et_location_readings
  end

  def calculate_et
    render json: {
      inputs: params,
      value: Evapotranspiration.new.potential_et
    }
  end
end
