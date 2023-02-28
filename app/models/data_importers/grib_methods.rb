require "open-uri"
require "open3"

module GribMethods
  def grib_dir
    "/tmp/gribdata"
  end

  def keep_grib
    ENV["KEEP_GRIB"] == "true" || false
  end

  # will allow importer to accept missing hourly gribs if imports have failed for two days
  def fetch(start_date: earliest_date, end_date: latest_date, all_dates: false, overwrite: false)
    ActiveRecord::Base.logger.level = :info

    dates = all_dates ? (start_date.to_date..end_date.to_date).to_a : missing_dates(start_date:, end_date:)
    return Rails.logger.info "#{name} :: Everything's up to date, nothing to do!" if dates.empty?

    dates.each do |date|
      if data_model.where(date:).exists? && !overwrite
        Rails.logger.info "#{name} :: Data already exists for #{date}, force with overwrite: true"
        import.succeed(date)
        next
      end
      fetch_day(date, force: date < 2.days.ago)
    rescue => e
      msg = "Failed to retrieve data for #{date}: #{e.message}"
      Rails.logger.warn "#{name} :: #{msg}"
      import.fail(date, msg)
      next
    end

    ActiveRecord::Base.logger.level = Rails.configuration.log_level
  end

  def download(url, path)
    case io = OpenURI.open_uri(url, open_timeout: 10, read_timeout: 60)
    when StringIO
      File.write(path, io.read)
    when Tempfile
      io.close
      FileUtils.mv(io.path, path)
    end
  end

  def central_time(date, hour)
    Time.use_zone("Central Time (US & Canada)") do
      Time.zone.local(date.year, date.month, date.day, hour)
    end
  end

  # returns 1 if it downloaded a file or one already existed
  def fetch_grib(file_url, local_file, msg_prefix = "")
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
