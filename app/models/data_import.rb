class DataImport < ApplicationRecord

  DAYS_BACK_WINDOW = 5

  def self.earliest_date
    Date.current - DAYS_BACK_WINDOW
  end

  def self.days_to_load
    successful_dates = successful.pluck(:readings_on)

    earliest_date.upto(Date.yesterday).reject do |date|
      successful_dates.include?(date)
    end
  end

  def self.successful
    where(status: 'successful')
  end

  def self.unsuccessful
    where(status: 'unsuccessful')
  end

  def self.create_successful_load(date)
    successful.where(readings_on: date).create!
  end

  def self.create_unsuccessful_load(date)
    unsuccessful.where(readings_on: date).create!
  end

  # run from console
  def self.check_statuses(start_date = earliest_date(), end_date = Date.today)
    message = []
    message << "Data load statuses for #{start_date} thru #{end_date}:"

    (start_date .. end_date).each do |date|
      statuses = DataImport.where(readings_on: date)
      if statuses.empty?
        message << "  #{date}: Data load not attempted."
      elsif statuses.unsuccessful.count > 0
        message << "  #{date}: FAIL"
        statuses.each do |status|
          if status.status == "unsuccessful"
            message << "    #{status.type} ==> FAIL"
          else
            message << "    #{status.type} ==> OK"
          end
        end
      else
        message << "  #{date}: OK"
      end
    end

    message.each { |m| Rails.logger.info m }
  end

  # sends status email if data loads have failed recently
  def self.send_status_email
    statuses = []
    send = false
    dates = earliest_date() .. Date.today - 1

    dates.each do |date| 
      status = DataImport.where(readings_on: date)
      send = true if status.empty? || status.unsuccessful.count > 0
      statuses << { date: date, status: status }
    end

    if send
      Rails.logger.info("DataImport :: Abnormal data load detected, sending status email.")
      StatusMailer.daily_mail(statuses).deliver
    else
      Rails.logger.info("DataImport :: All data loads successful.")
    end
  end
end
