class Insolation < ApplicationRecord

  def self.land_grid_values_for_date(grid, date)
    # value_grid = LandGrid.wisconsin_grid

    Insolation.where(date: date).each do |insol|
      grid[insol.latitude, insol.longitude] = insol.insolation
    end

    grid
  end

  def self.create_image(date)
    # return 'no_data.png' unless InsolationDataImport.successful.where(readings_on: date).exists?

    # image_name = "insolation_#{date.to_s(:number)}.png"
    # unless File.exists?(File.join(Rails.configuration.x.image.file_dir, image_name))
    #   insolations = land_grid_values_for_date(date)
    #   title = "Daily Insol (MJ day-1 m-2) for #{date.strftime('%-d %B %Y')}"
    #   image_name = ImageCreator.create_image(insolations, title, image_name)
    # end

    # return image_name
    if InsolationDataImport.successful.where(readings_on: date).exists?
      begin
        image_name = "insolation_#{date.to_s(:number)}.png"
        File.delete(image_name) if File.exists?(image_name)
        insolations = land_grid_values_for_date(LandGrid.wi_mn_grid, date)
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
