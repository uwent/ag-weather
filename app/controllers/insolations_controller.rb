class InsolationsController < ApplicationController

  # GET: returns insols for lat, long, date range
  def index
    end_date = params[:end_date] ? params[:end_date] : Date.today

    insols = Insolation.where(latitude: params[:lat], longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date], end_date)
      .order(:date)

    data = insols.collect do |insol|
      {
        date: insol.date.to_s,
        value: insol.insolation.round(3)
      }
    end

    render json: data
  end

  # GET: create map and return url to it
  def show
    begin
      date = Date.parse(params[:id])
    rescue
      date = latest_date
    end

    image_name = Insolation.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      url = image_url
    else
      image_name = Insolation.create_image(date)
      url = image_name == "no_data.png" ? "/no_data.png" : image_url
    end

    if request.format.png?
      render html: "<img src=#{url}>".html_safe
    else
      render json: { map: url }
    end
  end

  # GET: return all values for date
  def all_for_date
    begin
      date = Date.parse(params[:date])
    rescue
      date = latest_date
    end

    insols = Insolation.where("date = ?", date).order(:latitude, :longitude)
    data = []

    if insols.length > 0
      status = "OK"
      lats = insols.pluck(:latitude)
      longs = insols.pluck(:longitude)
      values = insols.pluck(:insolation)
      info = {
        lat_range: [lats.min, lats.max],
        long_range: [longs.min, longs.max],
        value_range: [values.min, values.max],
        value_unit: "Solar Insolation (MJ/day)"
      }
      data = insols.collect do |insol|
        {
          lat: insol.latitude.round(1),
          long: insol.longitude.round(1),
          value: insol.insolation.round(3)
        }
      end
    else
      status = "no data"
    end

    render json: {
      date: date,
      status: status,
      info: info,
      data: data
    }
  end

  # GET: valid params for api
  def info
    i = Insolation
    render json: {
      date_range: [i.minimum(:date).to_s, i.maximum(:date).to_s],
      lat_range: [i.minimum(:latitude), i.maximum(:latitude)],
      long_range: [i.minimum(:longitude), i.maximum(:longitude)],
      value_range: [i.minimum(:insolation), i.maximum(:insolation)]
    }
  end
end

private

def latest_date
  InsolationDataImport.successful.last.readings_on
end
