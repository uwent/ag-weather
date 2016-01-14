class EvapotranspirationDatum < ActiveRecord::Base

  def self.calculate_et_for_date(date)
    raise ActiveRecord::RecordNotFound unless data_sources_loaded?(date)

    create

    DataImport.create_successful_load('evapotranspiration', date)
  rescue StandardError=>e
    DataImport.create_unsuccessful_load('evapotranspiration', date)
    raise e
  end

  def self.data_sources_loaded?(date)
    !!DataImport.for_type('weather').successful.find_by(readings_on: date) &&
    !!DataImport.for_type('insolation').successful.find_by(readings_on: date)
  end
end
