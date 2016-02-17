class WeatherImporter
  REMOTE_BASE_DIR = "/pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp"

  def self.remote_dir(date)
    "#{REMOTE_BASE_DIR}/urma2p5.#{date.strftime('%Y%m%d')}"
  end

  def self.local_dir(date)
    savedir = "#{LOCAL_BASE_DIR}/gribdata/#{date.strftime('%Y%m%d')}"
    FileUtils.mkdir_p(savedir)
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

    start = central_time(date, 0)
    last = central_time(date, 23)

    (start.to_i..last.to_i).step(1.hour) do |time_in_sec|
      time = Time.at(time_in_sec).utc
      client.chdir(remote_dir(time.to_date))
      filename = remote_file_name(time.hour)
      local_file = "#{local_dir(date)}/#{date}.#{filename}"
      unless File.exist?(local_file)
        client.get(filename, "#{local_file}_part")
        FileUtils.mv("#{local_file}_part", local_file)
      end
    end
  end

  def self.load_database_for(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(local_dir(date))
    persist_day_to_db(weather_day)
  end

  def self.persist_day_to_db(weather_day)
    weather_data = []
    WiMn.each_point do |lat, long|
      temperatures = weather_day.temperatures_at(lat, long) || next
      dew_points = weather_day.dew_points_at(lat, long) || next

      weather_data << WeatherDatum.new(
                      latitude: lat,
                      longitude: long,
                      date: weather_day.date,
                      max_temperature: K_to_C(temperatures.max),
                      min_temperature: K_to_C(temperatures.min),
                      avg_temperature: K_to_C(weather_average(temperatures)),
                      vapor_pressure: dew_point_to_vapor_pressure(weather_average(dew_points)))
    end
    WeatherDatum.import weather_data
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

  def self.central_time(date, hour)
    Time.use_zone("Central Time (US & Canada)") do
      Time.zone.local(date.year, date.month, date.day, hour)
    end
  end
end
