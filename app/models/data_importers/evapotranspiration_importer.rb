class EvapotranspirationImporter < DataImporter
  def self.import
    EvapotranspirationDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date) &&
      InsolationDataImport.successful.find_by(readings_on: date)
  end

  def self.create_et_data
    dates = import.days_to_load
    if dates.size > 0
      dates.each { |date| calculate_et_for_date(date) }
    else
      Rails.logger.info "#{name} :: Everything's up to date, nothing to load!"
    end
  end

  def self.calculate_et_for_date(date)
    Rails.logger.info "#{name} :: Calculating ET for #{date}"
    start_time = Time.now
    import.start(date)

    unless data_sources_loaded?(date)
      import.fail(date, "Data sources not loaded for #{date}")
      return
    end

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
      import.succeed(date)
    end

    Evapotranspiration.create_image(date) unless Rails.env.test?

    Rails.logger.info "#{name} :: Completed ET calc & image creation for #{date} in #{elapsed(start_time)}."
  rescue => e
    import.fail(date, "Failed to calculate ET for #{date}: #{e.message}")
  end
end
