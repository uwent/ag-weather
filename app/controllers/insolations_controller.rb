class InsolationsController < ApplicationController

  def show
    date = Date.parse(params[:id])

    unless InsolationDataImport.successful.where(readings_on: date).exists?
      render json: { map: File.join(ImageCreator.url_path, 'no_data.png') }
    else
      insolations = Insolation.land_grid_values_for_date(date)
      title = "Daily Insol (MJ day-1 m-1) for #{date.strftime('%-d %B %Y')}"
      image_name = ImageCreator.create_image(insolations, title,
                                             "insolation_#{date.to_s(:number)}")
      render json: { map: File.join(ImageCreator.url_path, image_name) }
    end
  end
end
