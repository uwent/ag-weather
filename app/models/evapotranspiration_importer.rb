class EvapotranspirationImporter

  def self.create_et_data
    days_to_load = EvapotranspirationDataImport.days_to_load
    days_to_load.each do |day|
      calculate_et_for_date(day)
    end
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date) &&
      InsolationDataImport.successful.find_by(readings_on: date)
  end

  def self.calculate_et_for_date(date)
    EvapotranspirationDataImport.start(date)

    unless data_sources_loaded?(date)
      Rails.logger.warn "EvapotranspirationImporter :: FAIL: Data sources not loaded."
      EvapotranspirationDataImport.fail(date, "Data sources not loaded.")
      return
    end

    weather = WeatherDatum.land_grid_for_date(date)
    insols = Insolation.land_grid_values_for_date(LandGrid.new, date)

    ets = []
    LandExtent.each_point do |lat, long|
      if weather[lat, long].nil? || insols[lat, long].nil?
        Rails.logger.error("Failed to calculate evapotranspiration for #{date}, lat: #{lat} long: #{long}.")
        next
      end

      et = Evapotranspiration.new(
        latitude: lat,
        longitude: long,
        date: date)
      et.potential_et = et.calculate_et(insols[lat, long], weather[lat, long])
      ets << et
    end

    Evapotranspiration.where(date: date).delete_all
    Evapotranspiration.import(ets, validate: false)
    EvapotranspirationDataImport.succeed(date)
    Evapotranspiration.create_image(date)
  end

end
