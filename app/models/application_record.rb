class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.on(date)
    where(date:)
  end

  def self.all_for_date(date)
    where(date:).order(:latitude, :longitude)
  end

  def self.grid_summarize(sql)
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
    self.distinct.pluck(:date).count
  end

  def self.extent
    return nil unless :latitude && :longitude
    {
      latitude: [minimum(:latitude).to_s, maximum(:latitude).to_s],
      longitude: [minimum(:longitude).to_s, maximum(:longitude).to_s]
    }
  end
end
