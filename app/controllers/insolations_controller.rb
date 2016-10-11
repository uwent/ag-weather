class InsolationsController < ApplicationController

  def show
    date = begin
             Date.parse(params[:id])
           rescue ArgumentError
             Date.yesterday
           end
    
    image_name = Insolation.create_image(date)
    render json: { map: File.join(ImageCreator.url_path, image_name)  }
  end
end
