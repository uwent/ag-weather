class Insolation < ApplicationRecord

  def self.land_grid_values_for_date(date)
    value_grid = LandGrid.wi_mn_grid

    Insolation.where(date: date).each do |insol|
      value_grid[insol.latitude, insol.longitude] = insol.recording
    end

    value_grid
  end

  def self.create_image(date)
    return 'no_data.png' unless InsolationDataImport.successful.where(readings_on: date).exists?

    image_name = "insolation_#{date.to_s(:number)}.png"
    unless File.exists?(File.join(Rails.configuration.x.image.file_dir, image_name))
      insolations = land_grid_values_for_date(date)
      title = "Daily Insol (MJ day-1 m-2) for #{date.strftime('%-d %B %Y')}"
      image_name = ImageCreator.create_image(insolations, title, image_name)
    end

    return image_name
  end

end
