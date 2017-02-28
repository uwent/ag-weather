class Evapotranspiration < ActiveRecord::Base

  def self.land_grid_values_for_date(date)
    et_grid = LandGrid.wisconsin_grid

    Evapotranspiration.where(date: date).each do |et|
      et_grid[et.latitude, et.longitude] = et.potential_et
    end

    et_grid
  end

  def self.create_image(date)
    return File.join(ImageCreator.url_path, 'no_data.png') unless EvapotranspirationDataImport.successful.where(readings_on: date).exists?

    image_name = "evapo_#{date.to_s(:number)}.png"
    unless File.exists?(File.join(Rails.configuration.x.image.file_dir,
                                  image_name))
      ets = land_grid_values_for_date(date)
      title = "Estimated ET (Inches/day) for #{date.strftime('%-d %B %Y')}"
      image_name = ImageCreator.create_image(ets, title, image_name)
    end

    return image_name
  end

  def self.create_and_static_link_image(date=(Date.today - 1.day))
    image_name = create_image(date)
    link_name = File.join(Rails.configuration.x.image.file_dir,
                          "current_et.png")
    File.unlink(link_name) if File.symlink?(link_name)
    File.symlink(image_name, link_name)
  end

  def calculate_et(insolation, weather_data)
    EvapotranspirationCalculator.et(
      (weather_data.max_temperature + weather_data.min_temperature) / 2.0,
      weather_data.vapor_pressure,
      insolation,
      date.yday,
      latitude)
  end

  def has_required_data?
    weather && insolation
  end

  def weather
    @weather ||= WeatherDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def insolation
    @insolation ||= Insolation.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def already_calculated?
    Evapotranspiration.find_by(latitude: latitude, longitude: longitude, date: date)
  end
end
