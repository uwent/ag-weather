class EvapotranspirationDatum < ActiveRecord::Base
  extend AgwxBiophys::ET

  def self.create_et_data
    days_to_load = DataImport.days_to_load_for('evapotranspiration')

    days_to_load.each do |day|
      EvapotranspirationDatum.calculate_et_for_date(day)
    end
  end

  def self.calculate_et_for_date(date)
    raise ActiveRecord::RecordNotFound unless data_sources_loaded?(date)

    #TODO: The WI/MN boundaries need to be constants that live somewhere
    lat_values = 42.step(50,0.1).to_a
    long_values = 86.step(98,0.1).to_a

    lat_values.each do |lat|
      long_values.each do |long|
        create_et_for_point(lat, long, date)
      end
    end

    DataImport.create_successful_load('evapotranspiration', date)
  rescue StandardError=>e
    DataImport.create_unsuccessful_load('evapotranspiration', date)
    raise e
  end

  def self.create_et_for_point(lat, long, date)
    weather = WeatherDatum.find_by(latitude: lat, longitude: long, date: date)
    insol = InsolationDatum.find_by(latitude: lat, longitude: long, date: date)

    if weather && insol
      # inputs: all temperatures in C; vapor pressure in kPa; insolation in MJ/day
      potential_et = et(
        weather.max_temperature,
        weather.min_temperature,
        weather.avg_temperature,
        weather.vapor_pressure,
        insol.insolation,
        date.yday,
        lat
      )

      create(potential_et: potential_et, latitude: lat, longitude: long, date: date)
    else
      nil
    end
  end

  def self.data_sources_loaded?(date)
    DataImport.for_type('weather').successful.find_by(readings_on: date) &&
    DataImport.for_type('insolation').successful.find_by(readings_on: date)
  end
end
