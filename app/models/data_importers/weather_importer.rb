class WeatherImporter < DataImporter
  extend GribMethods

  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/rtma/prod"
  LOCAL_DIR = "#{grib_dir}/rtma"

  def self.data_class
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

  # convert central date and hour to UTC date
  def self.remote_url(date:, hour:)
    utc_date = central_time(date, hour).utc.strftime("%Y%m%d")
    "#{REMOTE_URL_BASE}/rtma2p5.#{utc_date}"
  end

  # convert central date and hour to UTC hour
  def self.remote_file(date:, hour:)
    utc_hour = central_time(date, hour).utc.strftime("%H")
    "rtma2p5.t#{utc_hour}z.2dvaranl_ndfd.grb2_wexp"
  end

  def self.fetch_day(date, force: false)
    start_time = Time.current

    Rails.logger.info "#{name} :: Fetching grib files for #{date}..."
    import.start(date)

    grib_dir = local_dir(date)
    download_gribs(date, force:)
    weather_day = WeatherDay.new(date)
    weather_day.load_from(grib_dir)
    persist_day_to_db(weather_day)
    FileUtils.rm_r grib_dir unless keep_grib

    import.succeed(date)
    WeatherDatum.create_image(date:, units: "F")
    Rails.logger.info "#{name} :: Completed weather load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to import weather data for #{date}: #{e}"
    import.fail(date, e)
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
        vapor_pressure: UnitConverter.temp_to_vp(dew_point),
        hours_rh_over_90: count_rh_over(observations, 90.0),
        avg_temp_rh_over_90: avg_temp_rh_over(observations, 90.0)
      )
    end

    WeatherDatum.transaction do
      WeatherDatum.where(date: weather_day.date).delete_all
      WeatherDatum.import!(weather_data)
    end
  end

  def self.count_rh_over(observations, rh_cutoff)
    observations.map(&:relative_humidity).count { |x| x >= rh_cutoff }
  end

  def self.avg_temp_rh_over(observations, rh_cutoff)
    rh_obs = observations.select { |obs| obs.relative_humidity >= rh_cutoff }
    (rh_obs.map(&:temperature).sum / rh_obs.size) if rh_obs.size >= 1
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
