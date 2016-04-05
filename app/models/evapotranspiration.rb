class Evapotranspiration < ActiveRecord::Base

  def calc_et(insol, weather_data)
    EvapotranspirationCalculator.et(
      (weather_data.max_temperature + weather_data.min_temperature) / 2.0,
      weather_data.vapor_pressure,
      insol.recording,
      date.yday,
      latitude)
  end

  def calculate_et
    return false unless has_required_data?
    return self if already_calculated?

    potential_et = EvapotranspirationCalculator.et(
      (weather.max_temperature + weather.min_temperature) / 2.0,
      weather.vapor_pressure,
      insolation.recording,
      date.yday,
      latitude
    )

    update_attributes!(potential_et: potential_et)
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
