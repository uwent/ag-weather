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
      image_url = File.join(ImageCreator.url_path, image_name)
      render json: { map: image_url }
    end
  end
end
