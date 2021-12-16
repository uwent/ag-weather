class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.latest_date
    maximum(:date)
  end

  def self.earliest_date
    minimum(:date)
  end
end
