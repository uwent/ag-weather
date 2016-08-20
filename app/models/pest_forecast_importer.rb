class PestForecastImporter

  def self.create_forecast_data
    days_to_load = PestForecastDataImport.days_to_load

    days_to_load.each do |day|
      calculate_forecast_for_date(day)
    end
  end

  def self.calculate_forecast_for_date(date)
    unless  data_sources_loaded?(date)
      PestForecastDataImport.create_unsuccessful_load(date)
      return
    end

    weather = WeatherDatum.land_grid_for_date(date)

    PestForecast.where(date: date).delete_all

    forecasts = []
    WiMn.each_point do |lat, long|
      next unless Wisconsin.inside?(lat, long)

      if weather[lat, long].nil?
        Rails.logger.error("Failed to calculate pest forcast for #{date}, lat: #{lat} long: #{long}.")
        next
      end

      forecast = PestForecast.new(latitude: lat,
                                  longitude: long,
                                  date: date)
      forecast.potato_blight_dsv =
        forecast.compute_potato_blight_dsv(weather[lat, long])
      forecasts << forecast
    end
    PestForecast.import(forecasts, validate: false)
    PestForecastDataImport.create_successful_load(date)
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end
end
