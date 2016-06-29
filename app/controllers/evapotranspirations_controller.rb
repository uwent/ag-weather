class EvapotranspirationsController < ApplicationController

  def show
    date = begin
             Date.parse(params[:id])
           rescue ArgumentError
             Date.yesterday
           end

    unless EvapotranspirationDataImport.successful.where(readings_on: date).exists?
      render json: { map: File.join(ImageCreator.url_path, 'no_data.png') }
    else
      ets = Evapotranspiration.land_grid_values_for_date(date)
      title = "Estimated ET (Inches/day) for #{date.strftime('%-d %B %Y')}"
      image_name = ImageCreator.create_image(ets, title,
                                       "evapo_#{date.to_s(:number)}.png")
      render json: { map: File.join(ImageCreator.url_path, image_name) }
    end
  end

  def index
    ets = Evapotranspiration.where(latitude: params[:lat],
                                   longitude: params[:long])
      .where("date >= ? and date <= ?", params[:start_date],
             params[:end_date])
      .order(:date)

    et_readings = ets.collect do |et|
      { date: et.date.to_s, value: et.potential_et.round(3) }
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
