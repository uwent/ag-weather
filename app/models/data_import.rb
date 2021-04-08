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

  def self.check_statuses
    ActiveRecord::Base.logger.level = 1
    Rails.logger.info("Data load statuses for last #{DAYS_BACK_WINDOW} days:")

    (earliest_date() .. Date.today).each do |day|
      statuses = DataImport.where(readings_on: day)
      if statuses.empty?
        Rails.logger.info("  #{day}: Data load not attempted.")
      elsif statuses.unsuccessful.count > 0
        Rails.logger.info("  #{day}: FAIL")
        statuses.each do |status|
          if status.status == "unsuccessful"
            Rails.logger.info("    #{status.type} ==> FAIL")
          else
            Rails.logger.info("    #{status.type} ==> OK")
          end
        end
      else
        Rails.logger.info("  #{day}: OK")
      end
    end
    ActiveRecord::Base.logger.level = 0
  end

  def self.send_status_email
    statuses = DataImport.where(readings_on: Date.today - 1)
    if statuses.unsuccessful.count > 0
      Rails.logger.info("DataImport :: At least one data load failed, sending status email.")
      StatusMailer.daily_mail(statuses).deliver
    else
      Rails.logger.info("DataImport :: All data loads successful, skipping status email.")
    end
  end
end
