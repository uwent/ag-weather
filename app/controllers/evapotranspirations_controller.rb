class EvapotranspirationsController < ApplicationController
  
  # GET: returns ets for lat, long, date range
  def index
    end_date = params[:end_date] ? params[:end_date] : Date.today

    ets = Evapotranspiration.where(latitude: params[:lat], longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date], end_date)
      .order(:date)

    data = ets.collect do |et|
      {
        date: et.date.to_s,
        value: et.potential_et.round(3)
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

    image_name = Evapotranspiration.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      url = image_url
    else
      image_name = Evapotranspiration.create_image(date)
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

    ets = Evapotranspiration.where("date = ?", date).order(:latitude, :longitude)
    data = []

    if ets.length > 0
      status = "OK"
      lats = ets.pluck(:latitude)
      longs = ets.pluck(:longitude)
      values = ets.pluck(:potential_et)

      info = {
        lat_range: [lats.min, lats.max],
        long_range: [longs.min, longs.max],
        value_range: [values.min, values.max],
        value_unit: "Potential ET (in/day)"
      }

      data = ets.collect do |et|
        {
          lat: et.latitude.round(1),
          long: et.longitude.round(1),
          value: et.potential_et.round(3)
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

  # GET: calculate et with arguments
  def calculate_et
    render json: {
      inputs: params,
      value: Evapotranspiration.new.potential_et
    }
  end

  # GET: valid params for api
  def info
    et = Evapotranspiration
    render json: {
      date_range: [et.minimum(:date).to_s, et.maximum(:date).to_s],
      lat_range: [et.minimum(:latitude), et.maximum(:latitude)],
      long_range: [et.minimum(:longitude), et.maximum(:longitude)],
      value_range: [et.minimum(:potential_et), et.maximum(:potential_et)]
    }
  end

end

private

def latest_date
  EvapotranspirationDataImport.successful.last.readings_on
end
