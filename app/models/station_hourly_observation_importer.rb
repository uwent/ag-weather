class StationHourlyObservationImporter
  LOCAL_BASE_DIR = "/tmp"

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
    CSV.parse(File.readlines(path).drop(4).join) do |row|
      reading_on = Date.parse(row[2])
      hour = row[3].to_i
      station.add_or_update_observation(Date.parse(row[2]), row[3].to_i,
                                        row[4], row[5], row[6])
    end
  end

end
