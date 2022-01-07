require "open-uri"

class WeatherImporter
  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp/gribdata"
  KEEP_GRIB = ENV["KEEP_GRIB"] || false
  MAX_TRIES = 3

  def self.fetch
    WeatherDataImport.days_to_load.each do |day|
      fetch_day(day)
    end
  end

  def self.download(url, path)
    case io = OpenURI::open_uri(url, open_timeout: 10, read_timeout: 60)
    when StringIO then File.open(path, 'w') { |f| f.write(io.read) }
    when Tempfile then io.close; FileUtils.mv(io.path, path)
    end
  end

  def self.local_dir(date)
    savedir = "#{LOCAL_BASE_DIR}/#{date.to_s(:number)}"
    FileUtils.mkdir_p(savedir)
    savedir
  end

  def self.remote_url(date)
    "#{REMOTE_URL_BASE}/urma2p5.#{date.to_s(:number)}"
  end

  def self.remote_file_name(hour)
    "urma2p5.t%02dz.2dvaranl_ndfd.grb2_wexp" % hour
  end

  def self.central_time(date, hour)
    Time.use_zone("Central Time (US & Canada)") do
      Time.zone.local(date.year, date.month, date.day, hour)
    end
  end

  def self.fetch_day(date)
    start_time = Time.current
    retries = 0
    WeatherDataImport.start(date)
    Rails.logger.info "WeatherImporter :: Fetching grib files for #{date}..."

    begin
      (central_time(date, 0).to_i..central_time(date, 23).to_i).step(1.hour) do |time_in_central|
        time = Time.at(time_in_central).utc
        remote_file = remote_file_name(time.hour)
        file_url = remote_url(time.to_date) + "/" + remote_file
        local_file = "#{local_dir(date)}/#{date}.#{remote_file}"

        if File.exist?(local_file)
          Rails.logger.info "Hour #{Time.at(time_in_central).strftime("%H")} ==> Exists"
        else
          Rails.logger.info "Hour #{Time.at(time_in_central).strftime("%H")} ==> GET #{file_url}"
          download(file_url, local_file)
        end
      end
    rescue => e
      puts e.message
      Rails.logger.warn "WeatherImporter :: Unable to retrieve remote weather file: #{e.message}"
      if (retries += 1) < MAX_TRIES
        Rails.logger.info "WeatherImporter :: Retrying connection in 10 seconds (attempt #{retries} of #{MAX_TRIES})"
        sleep(10)
        retry
      end
      WeatherDataImport.fail(date, "Unable to retrieve weather data: #{e.message}")
      return "Unable to retrieve weather data for #{date}."
    end

    import_weather_data(date)

    Rails.logger.info "WeatherImporter :: Completed weather load for #{date} in #{ActiveSupport::Duration.build((Time.now - start_time).round).inspect}."
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
      dew_point = weather_average(observations.map(&:dew_point))

      weather_data << WeatherDatum.new(
        latitude: lat,
        longitude: long,
        date: weather_day.date,
        max_temperature: temperatures.max,
        min_temperature: temperatures.min,
        avg_temperature: weather_average(temperatures),
        dew_point: dew_point,
        vapor_pressure: dew_point_to_vapor_pressure(dew_point),
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
    observations.map(&:relative_humidity).count { |x| x >= rh_cutoff }
  end

  def self.avg_temp_rh_over(observations, rh_cutoff)
    over_rh_observations = observations.select { |obs| obs.relative_humidity >= rh_cutoff }
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
    (array.max + array.min) / 2.0
  end


end
