class Insolation < ActiveRecord::Base

  def self.land_grid_for_date(date)
    insolation_grid = LandGrid.wi_mn_grid

    Insolation.where(date: date).each do |insol|
      insolation_grid[insol.latitude, insol.longitude] = insol
    end

    insolation_grid
  end
end
