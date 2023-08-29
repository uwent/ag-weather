class PestForecastImporter < DataImporter
  extend LocalDataMethods

  def self.data_class
    PestForecast
  end

  def self.import
    PestForecastDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(date:)
  end

  def self.create_data_for_date(date)
    date = date.to_date
    import.start(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = Weather.all_for_date(date)
    pfs = weather.collect { |w| PestForecast.new_from_weather(w) }

    PestForecast.transaction do
      PestForecast.where(date:).delete_all
      PestForecast.import!(pfs)
      import.succeed(date)
    end
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data for #{date}: #{e}"
    import.fail(date, e)
  end
end
