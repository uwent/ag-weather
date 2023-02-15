class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

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
