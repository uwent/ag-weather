class Insolation < ApplicationRecord

  def self.latest_date
    Insolation.maximum(:date)
  end

  def self.earliest_date
    Insolation.minimum(:date)
  end
  
  def self.land_grid_for_date(date)
    grid = LandGrid.new
    Insolation.where(date: date).each do |insol|
      lat, long = insol.latitude, insol.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = insol.insolation
    end
    grid
  end
  
  # Find max value for image creator with `Insolation.all.maximum(:insolation)`
  def self.create_image(date)
    if InsolationDataImport.successful.where(readings_on: date).exists?
      Rails.logger.info "Insolation :: Creating image for #{date}"
      begin
        data = land_grid_for_date(date)
        title = "Daily Insol (MJ day-1 m-2) for #{date.strftime('%-d %B %Y')}"
        file = image_name(date)
        ImageCreator.create_image(data, title, file, min_value: 0, max_value: 30)
      rescue => e
        Rails.logger.warn "Insolation :: Failed to create image for #{date}: #{e.message}"
        return "no_data.png"
      end
    else
      Rails.logger.warn "Insolation :: Failed to create image for #{date}: Insolation data missing"
      return "no_data.png"
    end
  end

  def self.image_name(date)
    "insolation_#{date.to_s(:number)}.png"
  end

end
