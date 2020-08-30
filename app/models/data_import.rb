class DataImport < ApplicationRecord

  DAYS_BACK_WINDOW = 3

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

  def self.send_status_email
    state = DataImport.where(readings_on: Date.today - 1)
    StatusMailer.daily_mail(state).deliver
  end
end
