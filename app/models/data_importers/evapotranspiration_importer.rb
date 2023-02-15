class EvapotranspirationImporter < DataImporter
  def self.import
    EvapotranspirationDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date) &&
      InsolationDataImport.successful.find_by(readings_on: date)
  end

  def self.create_data(dates = import.days_to_load, force: false)
    dates = dates.to_a unless dates.is_a? Array

    if dates.size == 0
      Rails.logger.info "#{name} :: Everything's up to date, nothing to do!"
      return true
    end

    dates.each do |date|
      if force || import.missing(date)
        create_data_for_date(date)
      else
        Rails.logger.info "#{name} :: Data already present, overwrite with force: true"
      end
    end
  end

  def self.create_data_for_date(date)
    raise StandardError.new("Data sources not found for #{date}") unless data_sources_loaded?(date)

    Rails.logger.info "#{name} :: Calculating ET for #{date}"
    start_time = Time.now
    import.start(date)

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

    Evapotranspiration.create_image(date)

    Rails.logger.info "#{name} :: Completed ET calc & image creation for #{date} in #{elapsed(start_time)}."
    true
  rescue => e
    msg = "Failed to calculate ET for #{date}: #{e.message}"
    Rails.logger.error "#{name} :: #{msg}"
    import.fail(date, msg)
    false
  end
end
