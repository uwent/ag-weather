class EvapotranspirationImporter
  def self.create_et_data
    days_to_load = EvapotranspirationDataImport.days_to_load_for

    days_to_load.each do |day|
      calculate_et_for_date(day)
    end
  end

  def self.calculate_et_for_date(date)
    return unless data_sources_loaded?(date)

    WiMn.each_point do |lat, long|
      Evapotranspiration.new(
          latitude: lat,
          longitude: long,
          date: date
        ).calculate_et
    end

    EvapotranspirationDataImport.create_successful_load(date)
  rescue ActiveRecord::RecordNotFound => e
    EvapotranspirationDataImport.create_unsuccessful_load(date)
    Rails.logger.error("Failed to calculate evapotranspiration for #{date}.")
    Rails.logger.error(e.backtrace)
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by!(readings_on: date) &&
      InsolationDataImport.successful.find_by!(readings_on: date)
  end
end
