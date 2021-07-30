module PestForecastImporter

  def self.create_forecast_data
    days_to_load = PestForecastDataImport.days_to_load

    days_to_load.each do |day|
      calculate_forecast_for_date(day)
    end
  end

  def self.calculate_forecast_for_date(date)
    unless data_sources_loaded?(date)
      Rails.logger.warn "PestForecastImporter :: FAIL: Data sources not loaded."
      PestForecastDataImport.fail(date, "Data sources not loaded.")
      return
    end

    weather = WeatherDatum.land_grid_for_date(date)
    forecasts = []
    
    Wisconsin.each_point do |lat, long|
      next unless Wisconsin.inside?(lat, long)

      if weather[lat, long].nil?
        Rails.logger.error("PestForecastImporter :: Failed to calculate pest forcast for #{date}, lat: #{lat} long: #{long}.")
        next
      end

      forecasts << PestForecast.new_from_weather(weather[lat, long])
    end

    PestForecast.where(date: date).delete_all
    PestForecast.import(forecasts, validate: false)
    PestForecastDataImport.succeed(date)
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end
end
