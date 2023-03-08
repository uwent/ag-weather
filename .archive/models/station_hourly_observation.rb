class StationHourlyObservation < ApplicationRecord
  belongs_to :station

  def wet_hour?
    relative_humidity > 85
  end
end
