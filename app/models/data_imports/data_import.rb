class DataImport < ApplicationRecord
  DAYS_BACK_WINDOW = (ENV["DAYS_BACK_WINDOW"] || 7).to_i

  def self.import_types
    [
      PrecipDataImport,
      WeatherDataImport,
      InsolationDataImport,
      EvapotranspirationDataImport,
      PestForecastDataImport,
      DegreeDayDataImport
    ].freeze
  end

  def self.latest_date
    Time.now.in_time_zone("US/Central").yesterday.to_date
  end

  def self.earliest_date
    Time.now.in_time_zone("US/Central").to_date - DAYS_BACK_WINDOW.days
  end

  def self.days_to_load
    successful_dates = successful.pluck(:date)

    earliest_date.upto(latest_date).reject do |date|
      successful_dates.include?(date)
    end
  end

  def self.pending
    where(status: "pending")
  end

  def self.started
    where(status: "started")
  end

  def self.successful
    where(status: "successful")
  end

  def self.failed
    where(status: "failed")
  end

  def self.start(date, message = nil)
    status = where(date:)
    opts = {status: "started", message:}
    status.exists? ? status.update!(opts) : status.create!(opts)
  end

  def self.succeed(date, message = nil)
    Rails.logger.info "#{name} :: Import completed successfully for #{date}"
    status = where(date:)
    opts = {status: "successful", message:}
    status.exists? ? status.update!(opts) : status.create!(opts)
  end

  def self.fail(date, message = nil)
    message ||= "No reason given"
    Rails.logger.warn "#{name} :: Import failed for #{date}: #{message}"
    status = where(date:)
    opts = {status: "failed", message:}
    status.exists? ? status.update!(opts) : status.create!(opts)
  end

  def self.create_pending(date)
    import_types.each { |i| i.create!(date:, status: "pending") }
  end

  # run this from console
  def self.check_statuses(start_date = earliest_date, end_date = latest_date)
    ActiveRecord::Base.logger.level = :info

    dates = start_date.to_date..end_date.to_date
    count = 0
    message = []
    message << "Data load statuses for #{start_date} thru #{end_date}:"

    dates.each do |date|
      # initialize import record
      import_types.each do |import|
        import.find_by(date:) || import.create(date:, status: "pending")
      end

      # describe import states
      statuses = DataImport.where(date:)
      if statuses.successful.size == import_types.size
        message << "  #{date}: OK"
      elsif statuses.pending.size == import_types.size
        count += import_types.size
        message << "  #{date}: PENDING"
      else
        message << "  #{date}"
        import_types.each do |type|
          status = type.find_by(date:)
          if status.status == "successful"
            message << "    #{status.type} ==> OK"
          else
            count += 1
            msg = "    #{status.type} ==> #{status.status.upcase}"
            msg += ": #{status.message}" if status.message
            message << msg
          end
        end
      end
    end

    ActiveRecord::Base.logger.level = Rails.configuration.log_level
    message.each { |m| Rails.logger.info m }
    {count:, message:}
  end

  # sends status email if data loads have failed recently
  def self.send_status_email
    status = check_statuses
    if status[:count] > 0
      Rails.logger.error "DataImport :: Abnormal data load detected, sending status email!"
      StatusMailer.status_mail(status[:message]).deliver
    else
      Rails.logger.info "DataImport :: All data loads successful, skipping status email."
    end
  end
end
