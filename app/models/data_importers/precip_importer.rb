class PrecipImporter < DataImporter
  extend GribMethods

  # these use the pcpanl product, vs the rtma product

  # REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/pcpanl/prod"

  # def self.remote_url(date:, hour: nil)
  #   "#{REMOTE_URL_BASE}/pcpanl.#{date.to_formatted_s(:number)}"
  # end

  # # precips are named by central time
  # def self.remote_file(date:, hour:)
  #   "st4_conus.#{date.to_formatted_s(:number)}#{"%.02d" % hour}.01h.grb2"
  # end

  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/rtma/prod"
  LOCAL_DIR = "#{grib_dir}/precip"

  def self.data_class
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

  # convert central date and hour to UTC date
  def self.remote_url(date:, hour:)
    utc_date = central_time(date, hour).utc.strftime("%Y%m%d")
    "#{REMOTE_URL_BASE}/rtma2p5.#{utc_date}"
  end

  # convert central date and hour to UTC hour
  def self.remote_file(date:, hour:)
    utc_time = central_time(date, hour).utc.strftime("%Y%m%d%H")
    "rtma2p5.#{utc_time}.pcp.184.grb2"
  end

  def self.fetch_day(date, force: false)
    start_time = Time.current
    import.start(date)

    Rails.logger.info "#{name} :: Fetching precip data for #{date}..."
    download_gribs(date, force:)

    Rails.logger.info "#{name} :: Loading files..."
    grid = load_from(local_dir(date))

    precips = grid.collect do |key, precip|
      latitude, longitude = key
      Precip.new(date:, latitude:, longitude:, precip:)
    end

    Precip.transaction do
      Precip.where(date:).delete_all
      Precip.import!(precips)
      import.succeed(date)
    end

    Rails.logger.info "#{name} :: Completed precip load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Failed to load precip data for #{date}: #{e}"
    import.fail(date, e)
  end

  def self.load_from(dirname)
    files = Dir["#{dirname}/*.grb2"]
    Rails.logger.warn "#{name} :: Trying to load less than 24 grib files (#{files.size})" if files.size < 24

    # array of grids
    hourly_grids = files.map { |file| load_grib(file) }

    daily_grid = {}
    hourly_grids.each do |grid|
      LandExtent.each_point do |lat, long|
        key = [lat, long]
        daily_grid[key] ||= 0.0
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
    grid.each do |key, vals|
      grid[key] = vals.empty? ? 0.0 : vals.sum(0.0) / vals.size
    end

    grid
  end
end
