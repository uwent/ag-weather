class PestForecastImporter < LocalDataImporter
  def self.data_model
    PestForecast
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.create_data_for_date(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = WeatherDatum.all_for_date(date)
    pfs = weather.collect { |w| PestForecast.new_from_weather(w) }

    PestForecast.transaction do
      PestForecast.where(date:).delete_all
      PestForecast.import!(pfs)
    end

    PestForecast.create_image(date:)

    true
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data #{date}: #{e.message}"
    false
  end
end
