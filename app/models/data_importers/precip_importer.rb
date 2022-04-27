class PrecipImporter < GribImporter
  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/pcpanl/prod"
  LOCAL_DIR = "#{GRIB_DIR}/precip"

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
    Rails.logger.info "#{name} :: Fetching precip data for #{date}..."
    import.start(date)
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

    if gribs == 0
      import.fail(date, "Failed to retrieve any grib files for #{date}")
      return
    end

    if gribs < 24
      unless force
        import.fail(date, "Failed to retrieve all grib files for #{date}")
        return
      end
    end

    import_precip_data(date)

    Rails.logger.info "#{name} :: Completed precip load for #{date} in #{elapsed(start_time)}."
  end

  def self.import_precip_data(date)
    precips = load_from(local_dir(date))
    write_to_db(precips, date)
    Precip.create_image(date) unless Rails.env.test?
  rescue => e
    import.fail(date, e.message)
  end

  def self.load_from(dirname)
    files = Dir["#{dirname}/*.grb2"]
    Rails.logger.warn "PrecipImprter :: Trying to load less than 24 grib files" if files.size < 24

    hourly_precips = []
    files.each_with_index do |file, i|
      hourly_precips[i] = load_grib(file)
    end

    precip_totals = LandGrid.new(default: 0.0)
    hourly_precips.each do |grid|
      grid.each_point do |lat, long|
        precip_totals[lat, long] += grid[lat, long]
      end
    end

    FileUtils.rm_r(dirname) unless KEEP_GRIB

    precip_totals
  end

  def self.load_grib(grib)
    data = LandGrid.new
    # can't use LandGrid's default because all the arrays would be the same object
    data.each_point do |lat, long|
      data[lat, long] = []
    end

    cmd = "grib_get_data -w shortName=tp #{grib}"
    Rails.logger.info "PCP grib cmd >> #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)

    stdout.each do |line|
      lat, long, precip = line.split
      lat = lat.to_f
      long = long.to_f - 360.0
      precip = precip.to_f
      if LandExtent.inside?(lat, long)
        lat = lat.round(1)
        long = long.round(1)
        precip = 0 if precip < 0
        data[lat, long] << precip
      end
    end

    # average all pts in a cell
    data.each_point do |lat, long|
      precips = data[lat, long]
      precip = precips.size > 0 ? precips.sum(0.0) / precips.size : 0.0
      data[lat, long] = precip
    end

    data
  end

  def self.write_to_db(data, date)
    precip_data = []
    data.each_point do |lat, long|
      precip_data << Precip.new(
        date: date,
        latitude: lat,
        longitude: long,
        precip: data[lat, long]
      )
    end

    Precip.transaction do
      Precip.where(date:).delete_all
      Precip.import(precip_data)
      import.succeed(date)
    end
  end
end
