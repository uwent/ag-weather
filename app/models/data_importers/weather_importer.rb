class WeatherImporter < DataImporter
  extend GribMethods

  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/rtma/prod"
  LOCAL_DIR = "#{grib_dir}/rtma"

  def self.data_model
    WeatherDatum
  end

  def self.import
    WeatherDataImport
  end

  def self.local_dir(date)
    savedir = "#{LOCAL_DIR}/#{date.to_formatted_s(:number)}"
    FileUtils.mkdir_p(savedir)
    savedir
  end

  def self.remote_url(date)
    "#{REMOTE_URL_BASE}/rtma2p5.#{date.to_formatted_s(:number)}"
  end

  def self.remote_file_name(hour)
    "rtma2p5.t%02dz.2dvaranl_ndfd.grb2_wexp" % hour
  end

  def self.fetch_day(date, force: false)
    start_time = Time.current

    Rails.logger.info "#{name} :: Fetching grib files for #{date}..."
    import.start(date)

    n_gribs = download_gribs(date)
    if n_gribs == 0
      raise StandardError.new "Failed to retrieve any grib files for #{date}"
    elsif n_gribs < 24 && !force
      raise StandardError.new "Failed to retrieve all grib files for #{date}, found #{n_gribs}. Override with force: true"
    end

    grib_dir = local_dir(date)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(grib_dir)
    persist_day_to_db(weather_day)
    FileUtils.rm_r grib_dir unless keep_grib

    WeatherDatum.create_image(date:) unless Rails.env.test?

    Rails.logger.info "#{name} :: Completed weather load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to import weather data for #{date}: #{e}"
    import.fail(date, e)
  end

  # try to get a grib for each hour
  def self.download_gribs(date)
    date = date.to_date
    hours = (central_time(date, 0).to_i..central_time(date, 23).to_i)
    gribs = 0

    hours.step(1.hour) do |time_in_central|
      time = Time.at(time_in_central).utc
      hour = Time.at(time_in_central).strftime("%H")
      remote_file = remote_file_name(time.hour)
      file_url = remote_url(time.to_date) + "/" + remote_file
      local_file = "#{local_dir(date)}/#{date}.#{remote_file}"
      gribs += fetch_grib(file_url, local_file, "RTMA #{hour}")
    end
    gribs
  end

  def self.persist_day_to_db(weather_day)
    weather_data = []

    LandExtent.each_point do |lat, long|
      observations = weather_day.observations_at(lat, long) || next
      temperatures = observations.map(&:temperature)
      humidities = observations.map(&:relative_humidity)
      dew_points = observations.map(&:dew_point)
      dew_point = true_avg(dew_points)

      weather_data << WeatherDatum.new(
        date: weather_day.date,
        latitude: lat,
        longitude: long,
        min_temp: temperatures.min,
        max_temp: temperatures.max,
        avg_temp: true_avg(temperatures),
        min_rh: humidities.min.clamp(0, 100),
        max_rh: humidities.max.clamp(0, 100),
        avg_rh: true_avg(humidities).clamp(0, 100),
        dew_point:,
        vapor_pressure: dew_point_to_vapor_pressure(dew_point),
        hours_rh_over_90: relative_humidity_over(observations, 90.0),
        avg_temp_rh_over_90: avg_temp_rh_over(observations, 90.0)
      )
    end

    WeatherDatum.transaction do
      WeatherDatum.where(date: weather_day.date).delete_all
      WeatherDatum.import(weather_data)
      import.succeed(weather_day.date)
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
    # units in: dew point in Celsius
    vapor_p_mb = 6.105 * Math.exp((2500000.0 / 461.0) * ((1.0 / 273.16) - (1.0 / (dew_point + 273.15))))
    vapor_p_mb / 10
  end

  def self.simple_avg(array)
    return 0.0 if array.empty?
    (array.max + array.min) / 2.0
  end

  def self.true_avg(array)
    return 0.0 if array.empty?
    array.compact.sum.to_f / array.size
  end
end
