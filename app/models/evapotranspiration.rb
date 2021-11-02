class Evapotranspiration <  ApplicationRecord

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

  def self.latest_date
    Evapotranspiration.maximum(:date)
  end

  def self.earliest_date
    Evapotranspiration.minimum(:date)
  end

  def calculate_et(insolation, weather_data)
    EvapotranspirationCalculator.et(
      (weather_data.max_temperature + weather_data.min_temperature) / 2.0,
      weather_data.vapor_pressure,
      insolation,
      date.yday,
      latitude)
  end

  def self.land_grid_for_date(date)
    grid = LandGrid.new
    Evapotranspiration.where(date: date).each do |et|
      lat, long = et.latitude, et.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = et.potential_et
    end
    grid
  end

  # Find max value for image creator with `Evapotranspiration.all.maximum(:potential_et)`
  def self.create_image(date)
    if EvapotranspirationDataImport.successful.where(readings_on: date).exists?
      Rails.logger.info "Evapotranspiration :: Creating image for #{date}"
      begin
        data = land_grid_for_date(date)
        title = "Estimated ET (Inches/day) for #{date.strftime('%-d %B %Y')}"
        file = image_name(date)
        ImageCreator.create_image(data, title, file, min_value: 0, max_value: 0.3)
      rescue => e
        Rails.logger.warn "Evapotranspiration :: Failed to create image for #{date}: #{e.message}"
        return "no_data.png"
      end
    else
      Rails.logger.warn "Evapotranspiration :: Failed to create image for #{date}: ET data missing"
      return "no_data.png"
    end
  end

  def self.image_name(date)
    "evapo_#{date.to_s(:number)}.png"
  end

end
