class EvapotranspirationImporter < LocalDataImporter
  def self.data_model
    Evapotranspiration
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date) &&
      InsolationDataImport.successful.find_by(readings_on: date)
  end

  def self.create_data_for_date(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = WeatherDatum.land_grid_for_date(date)
    insols = Insolation.land_grid_for_date(date)
    ets = []

    LandExtent.each_point do |lat, long|
      next if weather[lat, long].nil? || insols[lat, long].nil?

      et = Evapotranspiration.new(latitude: lat, longitude: long, date:)
      et.potential_et = et.calculate_et(insols[lat, long], weather[lat, long])
      ets << et
    end

    Evapotranspiration.transaction do
      Evapotranspiration.where(date:).delete_all
      Evapotranspiration.import(ets)
    end

    true
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data #{date}: #{e.message}"
    false
  end
end
