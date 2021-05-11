require 'net/ftp'
class WeatherImporter
  REMOTE_SERVER = "ftp.ncep.noaa.gov"
  REMOTE_BASE_DIR = "/pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp"
  MAX_TRIES = 3

  def self.fetch
    days_to_load = WeatherDataImport.days_to_load

    days_to_load.each do |day|
      self.fetch_day(day)
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
    client = Net::FTP.new(REMOTE_SERVER)
    # client.read_timeout = 10
    client.login
    # client.debug_mode = true
    client
  end

  def self.fetch_day(date)
    Rails.logger.info("WeatherImporter :: Connecting to #{REMOTE_SERVER}...")
    client = connect_to_server

    start = central_time(date, 0)
    last = central_time(date, 23)

    Rails.logger.info("WeatherImporter :: Fetching grib files for #{date}...")
    (start.to_i..last.to_i).step(1.hour) do |time_in_central|
      time = Time.at(time_in_central).utc
      remote_dir = remote_dir(time.to_date)
      remote_file = remote_file_name(time.hour)
      local_file = "#{local_dir(date)}/#{date}.#{remote_file}"
      if File.exist?(local_file)
        Rails.logger.info("Hour #{Time.at(time_in_central).strftime("%H")} ==> Exists")
      else
        retries = 0
        begin
          Rails.logger.info("Hour #{Time.at(time_in_central).strftime("%H")} ==> GET #{remote_dir}/#{remote_file}")
          client.chdir(remote_dir)
          client.get(remote_file, "#{local_file}_part")
        rescue => e
          Rails.logger.warn("Unable to retrieve remote weather file. Reason: #{e.message}")
          retry if (retries += 1) < MAX_TRIES
          WeatherDataImport.create_unsuccessful_load(date)
          return
        end
        FileUtils.mv("#{local_file}_part", local_file)
      end
    end
    self.import_weather_data(date)
  end

  def self.import_weather_data(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(local_dir(date))
    WeatherDatum.where(date: date).delete_all
    persist_day_to_db(weather_day)
    WeatherDataImport.where(readings_on: date).delete_all
    WeatherDataImport.create_successful_load(date)
    FileUtils.rm_r self.local_dir(date)
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
        hours_rh_over_85: relative_humidity_over(observations, 85.0),
        avg_temp_rh_over_85: avg_temp_rh_over(observations, 85.0),
        hours_rh_over_90: relative_humidity_over(observations, 90.0),
        avg_temp_rh_over_90: avg_temp_rh_over(observations, 90.0)
      )
    end

    WeatherDatum.import(weather_data, validate: false)
  end

  def self.relative_humidity_over(observations, rh_cutoff)
    observations.map(&:relative_humidity).select { |x| x >= rh_cutoff }.length
  end

  def self.avg_temp_rh_over(observations, rh_cutoff)
    over_rh_observations = observations.select { |observation| observation.relative_humidity >= rh_cutoff }
    if over_rh_observations.size >= 1
      (over_rh_observations.map(&:temperature).sum / over_rh_observations.size).round(2)
    end
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
