require "net/ftp"
require "open3"

class PrecipImporter
  REMOTE_SERVER = "ftp.ncep.noaa.gov"
  REMOTE_DIR_BASE = "/pub/data/nccf/com/pcpanl/prod"
  LOCAL_DIR = "/tmp/gribdata/precip"
  KEEP_GRIB = ENV["KEEP_GRIB"] || false

  def self.fetch
    days_to_load = PrecipDataImport.days_to_load
    days_to_load.each do |day|
      fetch_day(day)
    end
  end

  def self.connect_to_server
    Rails.logger.debug "PrecipImporter :: Connecting to #{REMOTE_SERVER}..."
    client = Net::FTP.new(REMOTE_SERVER, open_timeout: 10, read_timeout: 60)
    client.login
    client
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
    remote_dir = remote_dir(date)
    remote_file = remote_file(date)
    local_file = local_file(date)

    if File.exist?(local_file)
      Rails.logger.debug "File #{local_file} ==> Exists"
    else
      begin
        client = connect_to_server
        Rails.logger.debug "GET #{remote_dir}/#{remote_file} ==> #{local_file}"
        client.chdir(remote_dir)
        client.get(remote_file, "#{local_file}_part")
        FileUtils.mv("#{local_file}_part", local_file)
      rescue => e
        msg = "Unable to retrieve precip file: #{e.message}"
        Rails.logger.warn "PrecipImporter :: #{msg}"
        PrecipDataImport.fail(date, msg)
        return msg
      end
    end

    import_precip_data(date)

    Rails.logger.info "PrecipImporter :: Completed precip load for #{date} in #{(Time.current - start_time).to_i} seconds."
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
