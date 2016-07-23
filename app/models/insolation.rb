class Insolation < ActiveRecord::Base

  def self.land_grid_values_for_date(date)
    value_grid = LandGrid.wi_mn_grid

    Insolation.where(date: date).each do |insol|
      value_grid[insol.latitude, insol.longitude] = insol.recording
    end

    value_grid
  end
end
