class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  attribute :latitude, :float
  attribute :longitude, :float

  def self.on(date)
    where(date:)
  end

  def self.all_for_date(date)
    where(date:).order(:latitude, :longitude)
  end

  def self.grid_summarize(sql = nil)
    group(:latitude, :longitude)
      .order(:latitude, :longitude)
      .select(:latitude, :longitude, sql)
  end

  def self.latest_date
    maximum(:date)
  end

  def self.earliest_date
    minimum(:date)
  end

  def self.days
    distinct.pluck(:date).count
  end

  def self.extent
    {
      latitude: [minimum(:latitude).to_s, maximum(:latitude).to_s],
      longitude: [minimum(:longitude).to_s, maximum(:longitude).to_s]
    }
  rescue
  end

  def self.log_prefix(level = 0)
    "#{name}##{caller_locations[level].label} :: "
  end
end
