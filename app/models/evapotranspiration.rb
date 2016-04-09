class Evapotranspiration < ActiveRecord::Base

  def self.land_grid_values_for_date(date)
    et_grid = LandGrid.wi_mn_grid

    Evapotranspiration.where(date: date).each do |et|
      et_grid[et.latitude, et.longitude] = et.potential_et
    end

    et_grid
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
