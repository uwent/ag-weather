class DataImport < ApplicationRecord
  DAYS_BACK_WINDOW = 5

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
      started.on(date).create!
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
    status = on(date)
    if status.exists?
      status.update(status: "unsuccessful", message:)
    else
      unsuccessful.on(date).create!
    end
  end

  # run this from console
  def self.check_statuses(start_date = earliest_date, end_date = latest_date)
    message = []
    count = 0
    message << "Data load statuses for #{start_date} thru #{end_date}:"

    (start_date..end_date).each do |date|
      statuses = DataImport.on(date)
      if statuses.empty?
        count += 1
        message << "  #{date}: Data load not attempted."
      elsif statuses.unsuccessful.count > 0 || statuses.started.count > 0
        message << "  #{date}: PROBLEM"
        statuses.each do |status|
          case status.status
          when "unsuccessful"
            count += 1
            message << "    #{status.type} ==> FAIL: #{status.message}"
          when "started"
            count += 1
            message << "    #{status.type} ==> STARTED"
          when "successful"
            message << "    #{status.type} ==> OK"
          else
            count += 1
            message << "    #{status.type} ==> UNKNOWN"
          end
        end
      else
        message << "  #{date}: OK"
      end
    end

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
