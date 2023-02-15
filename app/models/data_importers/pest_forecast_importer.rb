class PestForecastImporter < DataImporter
  def self.import
    PestForecastDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.create_data(dates = import.days_to_load)
    dates = dates.to_a unless dates.is_a? Array

    if dates.size == 0
      Rails.logger.info "#{name} :: Everything's up to date, nothing to do!"
      return true
    end

    dates.each do |date|
      create_data_for_date(date)
    end
  end

  def self.create_data_for_date(date)
    raise StandardError.new("Weather data not found for #{date}") unless data_sources_loaded?(date)

    start_time = Time.now
    import.start(date)
    Rails.logger.info "#{name} :: Creating pest forecast data for #{date}"
    weather = WeatherDatum.all_for_date(date)
    forecasts = []

    weather.each do |w|
      forecasts << PestForecast.new_from_weather(w)
    end

    PestForecast.transaction do
      PestForecast.where(date:).delete_all
      PestForecast.import(forecasts)
      import.succeed(date)
    end

    Rails.logger.info "#{name} :: Completed pest forecast calc & image creation for #{date} in #{elapsed(start_time)}."
    true
  rescue => e
    msg = "Failed to calculate pest forecasts for #{date}: #{e.message}"
    Rails.logger.error "#{name} :: #{msg}"
    import.fail(date, msg)
    false
  end
end
