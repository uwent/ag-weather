require "open-uri"
require "open3"

class PrecipImporter

  REMOTE_DIR_BASE = "https://nomads.ncep.noaa.gov/pub/data/nccf/com/pcpanl/prod"
  LOCAL_DIR = "/tmp/gribdata/precip"
  KEEP_GRIB = ENV["KEEP_GRIB"] || false

  def self.fetch
    PrecipDataImport.days_to_load.each do |day|
      fetch_day(day)
    end
  end

  def self.download(url, path)
    case io = OpenURI::open_uri(url, open_timeout: 10, read_timeout: 60)
    when StringIO then File.open(path, 'w') { |f| f.write(io.read) }
    when Tempfile then io.close; FileUtils.mv(io.path, path)
    end
  end

  def self.local_file(date)
    FileUtils.mkdir_p(LOCAL_DIR)
    "#{LOCAL_DIR}/#{date.to_s(:number)}.grb2"
  end

  def self.remote_dir(date)
    "#{REMOTE_DIR_BASE}/pcpanl.#{date.to_s(:number)}"
  end

  def self.remote_file(date)
    "st4_conus.#{date.to_s(:number)}12.24h.grb2"
  end

  def self.fetch_day(date)
    start_time = Time.current
    PrecipDataImport.start(date)

    Rails.logger.info "PrecipImporter :: Fetching precip data for #{date}..."
    file_url = remote_dir(date) + "/" + remote_file(date)
    local_file = local_file(date)
    temp_file = local_file + "_part"

    if File.exist?(local_file)
      Rails.logger.debug "File #{local_file} ==> Exists"
    else
      begin
        Rails.logger.debug "GET #{file_url} ==> #{local_file}"
        download(file_url, local_file)
      rescue => e
        msg = "Unable to retrieve precip file: #{e.message}"
        Rails.logger.warn "PrecipImporter :: #{msg}"
        PrecipDataImport.fail(date, msg)
        return msg
      end
    end

    import_precip_data(date)

    Rails.logger.info "PrecipImporter :: Completed precip load for #{date} in #{ActiveSupport::Duration.build((Time.now - start_time).round).inspect}."
  end

  def self.import_precip_data(date)
    precips = load_from(local_file(date))
    write_to_db(precips, date)
    PrecipDataImport.succeed(date)
    Precip.create_image(date)
  end

  def self.load_from(grib)
    data = LandGrid.new
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

    FileUtils.rm_r grib unless KEEP_GRIB

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
      Precip.where(date: date).delete_all
      Precip.import(precip_data)
    end
  end
end
