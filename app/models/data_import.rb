class DataImport < ActiveRecord::Base

  DAYS_BACK_WINDOW = 3

  def self.earliest_date
    earliest_date = Date.today - DAYS_BACK_WINDOW
  end

  def self.days_to_load_for(type)
    earliest_date = Date.today - DaysBackWindow
    successful_loads = DataImport.where(data_type: type)
      .where(status: 'completed')
      .where('readings_from >= ?', earliest_date)

    dates_loaded = successful_loads.pluck(:readings_from)

    dates_to_load = []
    (earliest_date..Date.yesterday).each do |date|
      if dates_loaded.include?(date)
        next
      else
        dates_to_load << date
      end
    end

    dates_to_load
  end

  def self.successful_load(type, date)
    DataImport.create!(
      data_type: type,
      status: 'completed',
      readings_from: date
    )
  end

  def self.unsuccessful_load(type, date)
    DataImport.create!(
      data_type: type,
      status: 'attempted',
      readings_from: date
    )
  end

end
