class WeatherImporter
  REMOTE_BASE_DIR = "pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp"

  def self.remote_dir(date)
    "#{REMOTE_BASE_DIR}/urma2p5.#{date.strftime('%Y%m%d')}"
  end

  def self.local_dir(date)
    gribdir = "#{LOCAL_BASE_DIR}/gribdata"
    FileUtils.mkpath(gribdir) unless Dir.exists?(gribdir)
    savedir = "#{gribdir}/#{date.strftime('%Y%m%d')}"
    FileUtils.mkpath(savedir) unless Dir.exists?(savedir)
    savedir
  end

  def self.remote_file_name(hour)
    sprintf("urma2p5.t%02dz.2dvaranl_ndfd.grb2", hour)
  end

  def self.connect_to_server
    client = Net::FTP.new('ftp.ncep.noaa.gov')
    client.login
    client.passive = true
    client
  end

  def self.fetch_files(date)
    client = connect_to_server
    client.chdir(remote_dir(date))
    0.upto(23) do |hour|
      filename = remote_file_name(hour)
      client.get(filename, "#{local_dir(date)}/#{date}.#{filename}" )
    end
  end

  def self.load_database_for(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(local_dir(date))
    persist_day_to_db(weather_day)
  end

  def self.persist_day_to_db(weather_day)
    WiMn.each_point do |lat, long|
      temperatures = weather_day.temperatures_at(lat, long) || next
      dew_points = weather_day.dew_points_at(lat, long) || next

      WeatherDatum.create(
        latitude: lat,
        longitude: long,
        date: weather_day.date,
        max_temperature: K_to_C(temperatures.max),
        min_temperature: K_to_C(temperatures.min),
        avg_temperature: K_to_C(weather_average(temperatures)),
        vapor_pressure: dew_point_to_vapor_pressure(weather_average(dew_points)))
    end
  end

  def self.K_to_C(kelvin)
    kelvin - 273.15
  end

  def self.dew_point_to_vapor_pressure(dew_point)
    # units in: dew point in K
    vapor_p_mb = 6.105 * Math.exp((2500000.0 / 461.0) * ((1.0 / 273.16) - (1.0 / dew_point)))
    vapor_p_mb / 10
  end

  def self.weather_average(array)
    return 0.0 if array.empty?
    (array.max + array.min) / 2
  end
end
