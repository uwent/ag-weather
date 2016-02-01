class Evapotranspiration < ActiveRecord::Base
  include AgwxBiophys::ET

  def calculate_et
    return false unless has_required_data?
    return self if already_calculated?

    potential_et = et(
      weather.max_temperature,
      weather.min_temperature,
      weather.avg_temperature,
      weather.vapor_pressure,
      insolation.insolation,
      date.yday,
      latitude
    ).first

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
