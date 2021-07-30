module StationHourlyObservationImporter
  DATA_DIR = ENV['STATION_OBSERVATION_DIR'] || '/tmp/station_obs'

  def self.check_for_file_and_load
    datafiles = File.join(DATA_DIR, "*.dat")
    Dir.glob(datafiles).each do |path|
      Rails.logger.info("Processing #{path}")
      process_file = path + ".processing"
      File.rename(path, process_file)
      if self.load_data(process_file)
        File.delete(process_file) if File.exist?(process_file)
      end
    end
  end

  def self.get_location_from_file(path)
    location = ''
    CSV.foreach(path) do |row|
      location = row[1]
      break
    end
    return Station.where(name: location).first
  end

  def self.load_data(path)
    station = self.get_location_from_file(path)
    if station.nil?
      Rails.logger.warn("Unable to process (can't find station): #{path}")
      return false
    end

    last_reading = station.last_reading
    last_date = last_reading.nil? ? Date.new(1900,1,1) : last_reading.reading_on
    last_hour = last_reading.nil? ? 0 : last_reading.hour

    CSV.parse(File.readlines(path).drop(4).join) do |row|
      reading_on = Date.parse(row[2])
      next if reading_on > Date.today # there is a weird record in the data for 12/31 for Hancock
      hour = row[3].to_i
      if reading_on > last_date || (reading_on == last_date && hour > last_hour)
        station.add_observation(Date.parse(row[2]), row[3].to_i, row[8], row[9], row[11])
      end
    end

    return true
  end

end
