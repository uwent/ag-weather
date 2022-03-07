require "open-uri"
require "open3"

class PrecipImporter
  REMOTE_URL_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/pcpanl/prod"
  LOCAL_DIR = "/tmp/gribdata/precip"
  KEEP_GRIB = ENV["KEEP_GRIB"] == "true" || false
  MAX_TRIES = 3

  def self.fetch
    PrecipDataImport.days_to_load.each do |day|
      fetch_day(day)
    end
  end

  def self.download(url, path)
    case io = OpenURI.open_uri(url, open_timeout: 10, read_timeout: 60)
    when StringIO
      File.write(path, io.read)
    when Tempfile
      io.close
      FileUtils.mv(io.path, path)
    end
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

  def self.central_time(date, hour)
    Time.use_zone("Central Time (US & Canada)") do
      Time.zone.local(date.year, date.month, date.day, hour)
    end
  end

  def self.fetch_day(date)
    start_time = Time.current
    PrecipDataImport.start(date)
    retries = 0
    Rails.logger.info "PrecipImporter :: Fetching precip data for #{date}..."

    begin
      (central_time(date, 0).to_i..central_time(date, 23).to_i).step(1.hour) do |time_in_central|
        hour = Time.at(time_in_central).strftime("%H")
        time = Time.at(time_in_central).utc
        file_name = remote_file(time.to_date, time.strftime("%H"))
        file_url = remote_url(time.to_date) + "/" + file_name
        local_file = "#{local_dir(date)}/#{hour}_#{file_name}"

        if File.exist?(local_file)
          Rails.logger.debug "Hour #{hour} ==> Exists"
        else
          Rails.logger.debug "Hour #{hour} ==> GET #{file_url}"
          download(file_url, local_file)
        end
      end
    rescue => e
      Rails.logger.warn "PrecipImporter :: Unable to retrieve remote file: #{e.message}"
      if (retries += 1) < MAX_TRIES
        Rails.logger.info "PrecipImporter :: Retrying connection in 10 seconds (attempt #{retries} of #{MAX_TRIES})"
        sleep(10)
        retry
      end
      PrecipDataImport.fail(date, "Unable to retrieve precip data: #{e.message}")
      return "Unable to retrieve precip data for #{date}."
    end

    import_precip_data(date)

    Rails.logger.info "PrecipImporter :: Completed precip load for #{date} in #{ActiveSupport::Duration.build((Time.now - start_time).round).inspect}."
  end

  def self.import_precip_data(date)
    precips = load_from(local_dir(date))
    write_to_db(precips, date)
    PrecipDataImport.succeed(date)
    Precip.create_image(date)
  end

  def self.load_from(dirname)
    hourly_precips = []
    Dir["#{dirname}/*.grb2"].each_with_index do |file, i|
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
    Rails.logger.debug "grib cmd: #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)

    stdout.each do |line|
      lat, long, precip = line.split
      lat = lat.to_f
      long = long.to_f - 360.0
      precip = precip.to_f
      if LandExtent.inside?(lat, long)
        lat, long = lat.round(1), long.round(1)
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
    end
  end
end
