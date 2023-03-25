class WeatherImporter < DataImporter
  extend GribMethods

  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/rtma/prod"
  LOCAL_DIR = "#{grib_dir}/rtma"

  def self.data_class
    Weather
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
    import.start(date)
    Rails.logger.info "#{name} :: Fetching grib files for #{date}..."

    download_gribs(date, force:)
    wd = WeatherDay.new
    wd.load_from(local_dir(date))
    persist_day_to_db(date, wd)
    FileUtils.rm_r grib_dir unless keep_grib

    Weather.create_image(date:, units: "F")
    Rails.logger.info "#{name} :: Completed weather load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to import weather data for #{date}: #{e}"
    import.fail(date, e)
  end

  def self.persist_day_to_db(date, day)
    weather = []

    LandExtent.each_point do |lat, long|
      observations = day.observations_at(lat, long) || next
      temps = observations.map(&:temperature)
      dew_points = observations.map(&:dew_point)
      humidities = observations.map(&:relative_humidity)
      dew_point = true_avg(dew_points)
      vapor_pressure = UnitConverter.temp_to_vp(dew_point)

      weather << Weather.new(
        date:,
        latitude: lat,
        longitude: long,
        min_temp: temps.min,
        max_temp: temps.max,
        avg_temp: true_avg(temps),
        dew_point:,
        vapor_pressure:,
        min_rh: humidities.min,
        max_rh: humidities.max,
        avg_rh: true_avg(humidities),
        hours_rh_over_90: count_rh_over(humidities, 90.0),
        avg_temp_rh_over_90: avg_temp_rh_over(observations, 90.0)
      )
    end

    Weather.transaction do
      Weather.where(date:).delete_all
      Weather.import!(weather)
    end

    import.succeed(date)
  end

  def self.count_rh_over(humidities, rh_cutoff)
    humidities.count { |x| x >= rh_cutoff }
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
