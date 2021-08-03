class EvapotranspirationsController < ApplicationController
  def show
    begin
      date = Date.parse(params[:id])
    rescue ArgumentError
      date = Date.yesterday
    end

    image_name = Evapotranspiration.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      render json: { map: image_url }
    else
      image_name = Evapotranspiration.create_image(date)
      image_url = File.join(ImageCreator.url_path, image_name)
      render json: { map: image_url }
    end
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
    begin
      date = Date.parse(params[:date])
    rescue ArgumentError
      date = Date.yesterday
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
