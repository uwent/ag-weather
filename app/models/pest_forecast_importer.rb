module PestForecastImporter
  def self.create_forecast_data
    PestForecastDataImport.days_to_load.each do |date|
      calculate_forecast_for_date(date)
    end
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.calculate_forecast_for_date(date)
    unless data_sources_loaded?(date)
      Rails.logger.error "PestForecastImporter :: FAIL: Weather data not found for #{date}"
      PestForecastDataImport.fail(date, "Weather data not found")
      return
    end

    weather = WeatherDatum.land_grid_for_date(date)
    forecasts = []

    LandExtent.each_point do |lat, long|
      next if weather[lat, long].nil?
      forecasts << PestForecast.new_from_weather(weather[lat, long])
    end

    PestForecast.transaction do
      PestForecast.where(date: date).delete_all
      PestForecast.import(forecasts)
    end

    PestForecastDataImport.succeed(date)
  rescue => e
    msg = "Failed to calculate pest forecasts for #{date}: #{e.message}"
    Rails.logger.error "PestForecastImporter :: #{msg}"
    PestForecastDataImport.fail(date, msg)
  end
end
