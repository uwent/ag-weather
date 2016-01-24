class EvapotranspirationDatum < ActiveRecord::Base
  include AgwxBiophys::ET

  def calculate_et
    return unless has_data?
    return if already_done?

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

  def has_data?
    weather && insolation
  end

  def weather
    @weather ||= WeatherDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def insolation
    @insolation ||= InsolationDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def already_done?
    EvapotranspirationDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  end
end
