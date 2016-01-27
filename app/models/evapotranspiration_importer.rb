class EvapotranspirationImporter
  def self.create_et_data
    days_to_load = DataImport.days_to_load_for('evapotranspiration')

    days_to_load.each do |day|
      calculate_et_for_date(day)
    end
  end

  def self.calculate_et_for_date(date)
    return unless data_sources_loaded?(date)

    WiMn.each_point do |lat, long|
      EvapotranspirationDatum.new(
          latitude: lat,
          longitude: long,
          date: date
        ).calculate_et
    end

    DataImport.create_successful_load('evapotranspiration', date)
  rescue StandardError=>e
    DataImport.create_unsuccessful_load('evapotranspiration', date)
    raise e
  end

  def self.data_sources_loaded?(date)
    DataImport.for_type('weather').successful.find_by!(readings_on: date) &&
    DataImport.for_type('insolation').successful.find_by!(readings_on: date)
  end
end
