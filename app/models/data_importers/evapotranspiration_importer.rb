class EvapotranspirationImporter < DataImporter
  extend LocalDataMethods

  def self.data_class
    Evapotranspiration
  end

  def self.import
    EvapotranspirationDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(date:) && InsolationDataImport.successful.find_by(date:)
  end

  def self.create_data_for_date(date)
    date = date.to_date
    import.start(date)
    raise StandardError.new("Data sources not found") unless data_sources_loaded?(date)

    weather = Weather.land_grid(date:)
    insols = Insolation.hash_grid(date:)
    ets = []

    LandExtent.each_point do |lat, long|
      w = weather[lat, long]
      i = insols[[lat, long]]
      next unless w && i

      value = EvapotranspirationCalculator.et(
        avg_temp: w.avg_temp,
        avg_v_press: w.vapor_pressure,
        insol: i,
        day_of_year: date.yday,
        lat:
      )
      ets << Evapotranspiration.new(
        date:,
        latitude: lat,
        longitude: long,
        potential_et: value
      )
    end

    Evapotranspiration.transaction do
      Evapotranspiration.where(date:).delete_all
      Evapotranspiration.import!(ets)
    end

    import.succeed(date)
    Evapotranspiration.create_image(date:) unless date < 1.week.ago
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data #{date}: #{e}"
    import.fail(date, e)
  end
end
