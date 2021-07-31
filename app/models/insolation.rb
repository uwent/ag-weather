class Insolation < ApplicationRecord

  # def insolation
  #   @insolation ||= Insolation.find_by(latitude: latitude, longitude: longitude, date: date)
  # end

  def self.land_grid_values_for_date(date)
    value_grid = LandGrid.weather_grid

    Insolation.where(date: date).each do |insol|
      value_grid[insol.latitude, insol.longitude] = insol.insolation
    end

    value_grid
  end

  def self.create_image(date)
    if InsolationDataImport.successful.where(readings_on: date).exists?
      begin
        image_name = "insolation_#{date.to_s(:number)}.png"
        File.delete(image_name) if File.exists?(image_name)
        insolations = land_grid_values_for_date(date)
        title = "Daily Insol (MJ day-1 m-2) for #{date.strftime('%-d %B %Y')}"
        ImageCreator.create_image(insolations, title, image_name)
      rescue => e
        Rails.logger.warn "Insolation :: Failed to create image for " + date.to_s + ": #{e.message}"
      end
    else
      Rails.logger.warn "Insolation :: Failed to create image for " + date.to_s + ": Data source missing"
    end
  end

end
