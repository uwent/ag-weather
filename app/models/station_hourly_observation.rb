class StationHourlyObservation < ActiveRecord::Base
  belongs_to :station

  def wet_hour?
    relative_humidity > 90
  end
end
