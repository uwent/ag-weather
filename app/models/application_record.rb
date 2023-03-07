class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  attribute :latitude, :float
  attribute :longitude, :float

  def self.on(date)
    where(date:)
  end

  def self.latest_date
    maximum(:date)
  end

  def self.earliest_date
    minimum(:date)
  end

  def self.dates
    distinct.pluck(:date)
  end

  def self.dates_in_range(date_range)
    where(date: date_range).dates
  end

  def self.num_dates
    dates.size
  end

  def self.log_prefix(level = 0)
    "#{name}##{caller_locations[level].label} :: "
  end
end
