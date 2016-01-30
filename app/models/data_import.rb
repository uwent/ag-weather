class DataImport < ActiveRecord::Base

  DAYS_BACK_WINDOW = 3

  def self.earliest_date
    earliest_date = Date.current - DAYS_BACK_WINDOW
  end

  def self.days_to_load_for(type)
    successful_dates = for_type(type).successful.pluck(:readings_on)

    earliest_date.upto(Date.yesterday).reject do |date|
      successful_dates.include?(date)
    end
  end

  def self.for_type(type)
    where(data_type: type)
  end

  def self.successful
    where(status: 'successful')
  end

  def self.unsuccessful
    where(status: 'unsuccessful')
  end

  def self.create_successful_load(type, date)
    successful.for_type(type).where(readings_on: date).create!
  end

  def self.create_unsuccessful_load(type, date)
    unsuccessful.for_type(type).where(readings_on: date).create!
  end
end
