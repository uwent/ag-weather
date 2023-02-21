class DegreeDayImporter < LocalDataImporter
  def self.data_model
    DegreeDay
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.create_data_for_date(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = WeatherDatum.all_for_date(date)
    dds = weather.collect { |w| DegreeDay.new_from_weather(w) }

    DegreeDay.transaction do
      DegreeDay.where(date:).delete_all
      DegreeDay.import!(dds)
    end

    DegreeDay.create_image(date:) unless Rails.env.test?
    
    true
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data #{date}: #{e.message}"
    false
  end
end
