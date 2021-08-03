class Insolation < ApplicationRecord

  def self.land_grid_values_for_date(grid, date)
    insols = grid
    Insolation.where(date: date).each do |insol|
      lat = insol.latitude
      lon = insol.longitude
      next unless grid.inside?(lat, lon)
      insols[lat, lon] = insol.insolation
    end
    insols
  end

  def self.image_name(date)
    "insolation_#{date.to_s(:number)}.png"
  end

  def self.create_image(date)
    if InsolationDataImport.successful.where(readings_on: date).exists?
      begin
        # image_name = image_name(date)
        # image_filename = File.join(ImageCreator.file_path, image_name)
        # File.delete(image_filename) if File.exists?(image_filename)
        insolations = land_grid_values_for_date(LandGrid.wi_mn_grid, date)
        title = "Daily Insol (MJ day-1 m-2) for #{date.strftime('%-d %B %Y')}"
        ImageCreator.create_image(insolations, title, image_name(date))
      rescue => e
        Rails.logger.warn "Insolation :: Failed to create image for " + date.to_s + ": #{e.message}"
        return "no_data.png"
      end
    else
      Rails.logger.warn "Insolation :: Failed to create image for " + date.to_s + ": Data source missing"
      return "no_data.png"
    end
  end
end
