require 'net/ftp'
class WeatherImporter
  REMOTE_BASE_DIR = "/pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp"

  def self.fetch
    days_to_load = WeatherDataImport.days_to_load

    days_to_load.each do |day|
      self.fetch_day(day)
      self.import_weather_data(day)
      FileUtils.rm_r self.local_dir(day)
    end
  end

  def self.remote_dir(date)
    "#{REMOTE_BASE_DIR}/urma2p5.#{date.strftime('%Y%m%d')}"
  end

  def self.local_dir(date)
    savedir = "#{LOCAL_BASE_DIR}/gribdata/#{date.strftime('%Y%m%d')}"
    FileUtils.mkdir_p(savedir)
    savedir
  end

  def self.remote_file_name(hour)
    sprintf("urma2p5.t%02dz.2dvaranl_ndfd.grb2_wexp", hour)
  end

  def self.connect_to_server
    client = Net::FTP.new('ftp.ncep.noaa.gov')
    client.login
    client.passive = true
    client
  end

  def self.fetch_day(date)
    client = connect_to_server

    start = central_time(date, 0)
    last = central_time(date, 23)

    (start.to_i..last.to_i).step(1.hour) do |time_in_sec|
      time = Time.at(time_in_sec).utc
      client.chdir(remote_dir(time.to_date))
      filename = remote_file_name(time.hour)
      local_file = "#{local_dir(date)}/#{date}.#{filename}"
      unless File.exist?(local_file)
        begin
          client.get(filename, "#{local_file}_part")
        rescue Net::FTPPermError
          Rails.logger.warn("Unable to get weather file: #{filename}")
#          WeatherDataImport.create_unsuccessful_load(date)
          return
        end
        FileUtils.mv("#{local_file}_part", local_file)
      end
    end
  end

  def self.import_weather_data(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(local_dir(date))
    persist_day_to_db(weather_day)
    WeatherDataImport.create_successful_load(date)
  end

  def self.persist_day_to_db(weather_day)
    weather_data = []
    Wisconsin.each_point do |lat, long|
      observations = weather_day.observations_at(lat, long) || next
      temperatures = observations.map(&:temperature)
      dew_points = observations.map(&:dew_point)

      weather_data << WeatherDatum.new(
                      latitude: lat,
                      longitude: long,
                      date: weather_day.date,
                      max_temperature: temperatures.max,
                      min_temperature: temperatures.min,
                      avg_temperature: weather_average(temperatures),
                      vapor_pressure: dew_point_to_vapor_pressure(weather_average(dew_points)),
                      hours_rh_over_85: relative_humidity_over_85(observations))
    end
    WeatherDatum.import(weather_data, validate: false)
  end

  def self.relative_humidity_over_85(observations)
    observations.map(&:relative_humidity).select { |x| x >= 85.0 }.length
  end

  def self.dew_point_to_vapor_pressure(dew_point)
    # units in: dew point in Celcius
    vapor_p_mb = 6.105 * Math.exp((2500000.0 / 461.0) * ((1.0 / 273.16) - (1.0 / (dew_point + 273.15))))
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
