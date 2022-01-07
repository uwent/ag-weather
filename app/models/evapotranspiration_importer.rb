class EvapotranspirationImporter
  def self.create_et_data
    EvapotranspirationDataImport.days_to_load.each do |date|
      calculate_et_for_date(date)
    end
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date) &&
      InsolationDataImport.successful.find_by(readings_on: date)
  end

  def self.calculate_et_for_date(date)
    start_time = Time.now
    EvapotranspirationDataImport.start(date)
    Rails.logger.info "EvapotranspirationImporter :: Calculating ET for #{date}"

    unless data_sources_loaded?(date)
      Rails.logger.warn "EvapotranspirationImporter :: FAIL: Data sources not loaded"
      EvapotranspirationDataImport.fail(date, "Data sources not loaded")
      return
    end

    weather = WeatherDatum.land_grid_for_date(date)
    insols = Insolation.land_grid_for_date(date)
    ets = []

    LandExtent.each_point do |lat, long|
      next if weather[lat, long].nil? || insols[lat, long].nil?

      et = Evapotranspiration.new(latitude: lat, longitude: long, date: date)
      et.potential_et = et.calculate_et(insols[lat, long], weather[lat, long])
      ets << et
    end

    Evapotranspiration.transaction do
      Evapotranspiration.where(date: date).delete_all
      Evapotranspiration.import(ets)
    end

    EvapotranspirationDataImport.succeed(date)
    Evapotranspiration.create_image(date)

    Rails.logger.info "EvapotranspirationImporter :: Completed ET calc & image creation for #{date} in #{ActiveSupport::Duration.build((Time.now - start_time).round).inspect}."
  rescue => e
    msg = "Failed to calculate ET for #{date}: #{e.message}"
    Rails.logger.error "EvapotranspirationImporter :: #{msg}"
    EvapotranspirationDataImport.fail(date, msg)
  end
end
