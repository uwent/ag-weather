class DegreeDayImporter < DataImporter
  extend LocalDataMethods

  def self.data_model
    DegreeDay
  end

  def self.import
    DegreeDayDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(date:)
  end

  def self.create_data_for_date(date)
    date = date.to_date
    import.start(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = WeatherDatum.all_for_date(date)
    dds = weather.map { |w| DegreeDay.new_from_weather(w) }

    DegreeDay.transaction do
      DegreeDay.where(date:).delete_all
      DegreeDay.import!(dds)
      import.succeed(date)
    end

    DegreeDay.create_image(date:) unless Rails.env.test?
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data for #{date}: #{e}"
    import.fail(date, e)
  end
end
