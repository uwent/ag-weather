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

    Rails.logger.info "#{name} :: Loading files..."
    wd = WeatherDay.new
    wd.load_from(local_dir(date))
    persist_day_to_db(date, wd)
    FileUtils.rm_r grib_dir unless keep_grib
    Rails.logger.info "#{name} :: Completed weather load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to import weather data for #{date}: #{e}"
    import.fail(date, e)
  end

  def self.persist_day_to_db(date, day)
    weather = []

    LandExtent.each_point do |lat, lng|
      observations = day.observations_at(lat, lng) || next
      w = Weather.new_from_observations(observations)
      w.date = date
      w.latitude = lat
      w.longitude = lng
      weather << w
    end

    Weather.transaction do
      Weather.where(date:).delete_all
      Weather.import!(weather)
      import.succeed(date)
    end
  end
end
