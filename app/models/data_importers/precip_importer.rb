class PrecipImporter < DataImporter
  extend GribMethods

  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/pcpanl/prod"
  LOCAL_DIR = "#{grib_dir}/precip"

  def self.data_model
    Precip
  end

  def self.import
    PrecipDataImport
  end

  def self.local_dir(date)
    dir = "#{LOCAL_DIR}/#{date.to_formatted_s(:number)}"
    FileUtils.mkdir_p(dir)
    dir
  end

  def self.remote_url(date)
    "#{REMOTE_URL_BASE}/pcpanl.#{date.to_formatted_s(:number)}"
  end

  def self.remote_file(date, hour)
    "st4_conus.#{date.to_formatted_s(:number)}#{hour}.01h.grb2"
  end

  def self.fetch_day(date, force: false)
    start_time = Time.current
    date = date.to_date
    Rails.logger.info "#{name} :: Fetching precip data for #{date}..."
    import.start(date)

    # download grib files
    n_gribs = download_gribs(date)
    if n_gribs == 0
      raise StandardError.new "Failed to retrieve any grib files for #{date}"
    elsif n_gribs < 24 && !force
      raise StandardError.new "Failed to retrieve all grib files for #{date}, found #{n_gribs}. Override with force: true"
    end

    grid = load_from(local_dir(date))
    precips = grid.map do |key, value|
      Precip.new(date:, latitude: key[0], longitude: key[1], precip: value)
    end

    Precip.transaction do
      Precip.where(date:).delete_all
      Precip.import!(precips)
      import.succeed(date)
    end

    Precip.create_image(date:) unless Rails.env.test?

    Rails.logger.info "#{name} :: Completed precip load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to load precip data for #{date}: #{e}"
    import.fail(date, e)
  end

  def self.download_gribs(date)
    date = date.to_date
    hours = central_time(date, 0).to_i..central_time(date, 23).to_i
    gribs = 0

    # try to get a grib for each hour
    hours.step(1.hour) do |time_in_central|
      time = Time.at(time_in_central).utc
      hour = Time.at(time_in_central).strftime("%H")
      file_name = remote_file(time.to_date, time.strftime("%H"))
      file_url = remote_url(time.to_date) + "/" + file_name
      local_file = "#{local_dir(date)}/#{hour}_#{file_name}"
      gribs += fetch_grib(file_url, local_file, "PCP #{hour}")
    end
    gribs
  end

  def self.load_from(dirname)
    files = Dir["#{dirname}/*.grb2"]
    Rails.logger.warn "#{name} :: Trying to load less than 24 grib files (#{files.size})" if files.size < 24

    # array of grids
    hourly_grids = files.map { |file| load_grib(file) }

    daily_grid = Hash.new(0.0)
    hourly_grids.each do |grid|
      LandExtent.each_point do |lat, long|
        key = [lat, long]
        daily_grid[key] += grid[key] || 0.0
      end
    end

    FileUtils.rm_r(dirname) unless keep_grib

    daily_grid
  end

  def self.load_grib(grib)
    cmd = "grib_get_data -w shortName=tp #{grib}"
    Rails.logger.info "PCP grib cmd >> #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)

    # collect all precips and assign them to a grid point
    grid = {}
    stdout.each do |line|
      lat, long, precip = line.split
      lat = lat.to_f.round(1)
      long = (long.to_f - 360.0).round(1)
      next unless LandExtent.inside?(lat, long)
      precip = precip.to_f
      precip = 0 if precip < 0
      key = [lat, long]
      grid[key] ||= []
      grid[key] << precip
    end

    # average all pts in a cell
    grid.each do |key, value|
      grid[key] = value.empty? ? 0.0 : value.sum(0.0) / value.size
    end

    grid
  end
end
