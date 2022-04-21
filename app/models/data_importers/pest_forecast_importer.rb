class PestForecastImporter < DataImporter
  def self.import
    PestForecastDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.create_forecast_data
    dates = import.days_to_load
    if dates.size > 0
      dates.each { |date| calculate_forecast_for_date(date) }
    else
      Rails.logger.info "#{self.name} :: Everything's up to date, nothing to do!"
    end
  end

  def self.calculate_forecast_for_date(date)
    Rails.logger.info "#{self.name} :: Fetching insolation data for #{date}"
    start_time = Time.now
    
    unless data_sources_loaded?(date)
      import.fail(date, "Weather data not found for #{date}")
      return
    end

    import.start(date)
    weather = WeatherDatum.land_grid_for_date(date)
    forecasts = []

    LandExtent.each_point do |lat, long|
      next if weather[lat, long].nil?
      forecasts << PestForecast.new_from_weather(weather[lat, long])
    end

    PestForecast.transaction do
      PestForecast.where(date:).delete_all
      PestForecast.import(forecasts)
      import.succeed(date)
    end

    PestForecast.create_dd_map("dd_50_86") unless Rails.env.test?

    Rails.logger.info "PestForecastImporter :: Completed pest forecast calc & image creation for #{date} in #{elapsed(start_time)}."
  rescue => e
    PestForecastDataImport.fail(date, "Failed to calculate pest forecasts for #{date}: #{e.message}")
    return
  end
end
