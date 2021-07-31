class Evapotranspiration < ApplicationRecord

  def self.land_grid_values_for_date(grid, date)
    # et_grid = LandGrid.weather_grid

    Evapotranspiration.where(date: date).each do |et|
      grid[et.latitude, et.longitude] = et.potential_et
    end

    grid
  end

  def calculate_et(insolation, weather_data)
    EvapotranspirationCalculator.et(
      (weather_data.max_temperature + weather_data.min_temperature) / 2.0,
      weather_data.vapor_pressure,
      insolation,
      date.yday,
      latitude)
  end

  # def has_required_data?
  #   weather && insolation
  # end

  # def weather
  #   @weather ||= WeatherDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  # end

  # def insolation
  #   @insolation ||= Insolation.find_by(latitude: latitude, longitude: longitude, date: date)
  # end

  # def already_calculated?
  #   Evapotranspiration.find_by(latitude: latitude, longitude: longitude, date: date)
  # end 

  def self.create_image(date)
    if EvapotranspirationDataImport.successful.where(readings_on: date).exists?
      begin
        image_name = "evapo_#{date.to_s(:number)}.png"
        File.delete(image_name) if File.exists?(image_name)
        ets = land_grid_values_for_date(WiMn.new, date)
        title = "Estimated ET (Inches/day) for #{date.strftime('%-d %B %Y')}"
        ImageCreator.create_image(ets, title, image_name)
      rescue => e
        Rails.logger.warn "Evapotranspiration :: Failed to create image for " + date.to_s + ": #{e.message}"
      end
    else
      Rails.logger.warn "Evapotranspiration :: Failed to create image for " + date.to_s + ": Data sources missing"
    end
  end

end
