class DataImport < ApplicationRecord
  DAYS_BACK_WINDOW = (ENV["DAYS_BACK_WINDOW"] || 7).to_i

  def self.import_types
    [
      WeatherDataImport,
      PrecipDataImport,
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
    (Time.now.in_time_zone("US/Central") - DAYS_BACK_WINDOW.days).to_date
  end

  def self.days_to_load
    successful_dates = successful.pluck(:readings_on)

    earliest_date.upto(latest_date).reject do |date|
      successful_dates.include?(date)
    end
  end

  def self.on(date)
    where(readings_on: date)
  end

  def self.missing(date)
    on(date).successful.size == 0
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

  def self.unsuccessful
    where(status: "unsuccessful")
  end

  def self.start(date, message = nil)
    status = on(date)
    if status.exists?
      status.update(status: "started", message:)
    else
      started.on(date).pending.create!
    end
  end

  def self.succeed(date, message = nil)
    status = on(date)
    if status.exists?
      status.update(status: "successful", message:)
    else
      successful.on(date).create!
    end
  end

  def self.fail(date, message = nil)
    message ||= "No reason given"
    Rails.logger.warn "#{name} :: Import failed for #{date}: #{message}"
    status = on(date)
    if status.exists?
      status.update(status: "unsuccessful", message:)
    else
      create!(readings_on: date, status: "unsuccessful", message:)
    end
  end

  # run this from console
  def self.check_statuses(start_date = earliest_date, end_date = latest_date)
    initial_log_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1

    message = []
    count = 0
    message << "Data load statuses for #{start_date} thru #{end_date}:"

    (start_date..end_date).each do |date|
      statuses = DataImport.on(date)
      if statuses.empty?
        count += 1
        message << "  #{date}: Data load not attempted."
      elsif statuses.successful.size == import_types.size
        message << "  #{date}: OK"
      else
        message << "  #{date}"
        import_types.each do |type|
          status = type.find_by(readings_on: date)
          if status
            case status.status
            when "successful"
              message << "    #{status.type} ==> OK"
            else
              count += 1
              message << "    #{status.type} ==> #{status.status.upcase}: #{status.message} (#{DataImporter.elapsed(status.updated_at)} ago)"
            end
          else
            count += 1
            message << "    #{type} ==> PENDING"
          end
        end
      end
    end

    ActiveRecord::Base.logger.level = initial_log_level

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
