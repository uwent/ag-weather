require "net/ftp"

class WeatherImporter

  REMOTE_SERVER = "ftp.ncep.noaa.gov"
  REMOTE_BASE_DIR = "/pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp/gribdata"
  MAX_TRIES = 10
  KEEP_GRIB = ENV["KEEP_GRIB"] || false

  def self.fetch
    WeatherDataImport.days_to_load.each { |day| fetch_day(day) }
  end

  def self.remote_dir(date)
    "#{REMOTE_BASE_DIR}/urma2p5.#{date.to_s(:number)}"
  end

  def self.local_dir(date)
    savedir = "#{LOCAL_BASE_DIR}/#{date.to_s(:number)}"
    FileUtils.mkdir_p(savedir)
    savedir
  end

  def self.remote_file_name(hour)
    sprintf("urma2p5.t%02dz.2dvaranl_ndfd.grb2_wexp", hour)
  end

  def self.connect_to_server
    Rails.logger.info "WeatherImporter :: Connecting to #{REMOTE_SERVER}..."
    client = Net::FTP.new(REMOTE_SERVER)
    client.login
    client
  end

  def self.fetch_day(date)
    retries = 0
    WeatherDataImport.start(date)

    begin
      client = connect_to_server

      Rails.logger.info "WeatherImporter :: Fetching grib files for #{date}..."
      first = central_time(date, 0)
      last = central_time(date, 23)
      
      (first.to_i..last.to_i).step(1.hour) do |time_in_central|
        time = Time.at(time_in_central).utc
        remote_dir = remote_dir(time.to_date)
        remote_file = remote_file_name(time.hour)
        local_file = "#{local_dir(date)}/#{date}.#{remote_file}"

        if File.exist?(local_file)
          Rails.logger.info "Hour #{Time.at(time_in_central).strftime("%H")} ==> Exists"
        else
          Rails.logger.info "Hour #{Time.at(time_in_central).strftime("%H")} ==> GET #{remote_dir}/#{remote_file}"
          client.chdir(remote_dir)
          Timeout.timeout(60) do
            client.get(remote_file, "#{local_file}_part")
          end
          FileUtils.mv("#{local_file}_part", local_file)
        end
      end
    rescue => e
      Rails.logger.warn "WeatherImporter :: Unable to retrieve remote weather file. Reason: #{e.message}"
      client.close
      if (retries += 1) < MAX_TRIES
        Rails.logger.info "WeatherImporter :: Retrying connection in 10 seconds (attempt #{retries} of #{MAX_TRIES})"
        sleep(10)
        retry
      end
      WeatherDataImport.fail(date, "Unable to retrieve weather data: #{e.message}")
      return "Unable to retrieve weather data for #{date}."
    end

    import_weather_data(date)
  end

  def self.import_weather_data(date)
    grib_dir = local_dir(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(grib_dir)
    persist_day_to_db(weather_day)
    WeatherDataImport.succeed(date)
    FileUtils.rm_r grib_dir unless KEEP_GRIB
    WeatherDatum.create_image(date)
  end

  def self.persist_day_to_db(weather_day)
    weather_data = []

    LandExtent.each_point do |lat, long|
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

    WeatherDatum.transaction do
      WeatherDatum.where(date: weather_day.date).delete_all
      WeatherDatum.import(weather_data)
    end
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
