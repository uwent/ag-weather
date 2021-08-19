class InsolationsController < ApplicationController

  def show
    begin
      date = Date.parse(params[:id])
    rescue ArgumentError
      date = Date.yesterday
    end

    image_name = Insolation.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      render json: { map: image_url }
    else
      image_name = Insolation.create_image(date)
      if image_name == "no_data.png"
        render json: { map: "/no_data.png" }
      else
        image_url = File.join(ImageCreator.url_path, image_name)
        render json: { map: image_url }
      end
    end
  end

  def index
    insols = Insolation.where(latitude: params[:lat], longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date], params[:end_date])
      .order(:date)

    insol_readings = insols.collect do |insol|
      {
        date: insol.date.to_s,
        value: insol.insolation.round(3)
      }
    end

    render json: insol_readings
  end

  def all_for_date
    begin
      date = Date.parse(params[:date])
    rescue ArgumentError
      date = Date.yesterday
    end
    insols = Insolation.where("date = ?", date).order(:latitude, :longitude)

    insol_readings = insols.collect do |insol|
      {
        lat: insol.latitude.round(1),
        long: insol.longitude.round(1),
        value: insol.insolation.round(3)
      }
    end
    render json: insol_readings
  end
end
