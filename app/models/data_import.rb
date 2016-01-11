class DataImport < ActiveRecord::Base

  DAYS_BACK_WINDOW = 3

  def self.earliest_date
    earliest_date = Date.today - DAYS_BACK_WINDOW
  end

  def self.days_to_load_for(type)
    successful_dates = for_type(type).successful.pluck(:readings_from)

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

end
