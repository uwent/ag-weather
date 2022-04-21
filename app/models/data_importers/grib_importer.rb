require "open-uri"
require "open3"

class GribImporter < DataImporter
  GRIB_DIR = "/tmp/gribdata"
  KEEP_GRIB = ENV["KEEP_GRIB"] == "true" || false

  # will allow importer to accept missing hourly gribs if imports have failed for two days
  def self.fetch
    dates = import.days_to_load
    if dates.size > 0
      dates.each { |date| fetch_day(date, force: date < 2.days.ago) }
    else
      Rails.logger.info "#{self.name} :: Everything's up to date, nothing to do!"
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

  def self.central_time(date, hour)
    Time.use_zone("Central Time (US & Canada)") do
      Time.zone.local(date.year, date.month, date.day, hour)
    end
  end

  # returns 1 if it downloaded a file or one already existed
  def self.fetch_grib(file_url, local_file, msg_prefix = "")
    if File.exist?(local_file)
      Rails.logger.info "#{msg_prefix} ==> Exists"
      return 1
    end

    Rails.logger.info "#{msg_prefix} ==> GET #{file_url}"
    begin
      download(file_url, local_file)
      1
    rescue => e
      Rails.logger.warn "#{msg_prefix} ==> FAIL: #{e.message}"
      0
    end
  end
end
