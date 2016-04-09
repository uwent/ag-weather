class WeatherDatum < ActiveRecord::Base
  def self.land_grid_for_date(date)
    weather_grid = LandGrid.wi_mn_grid

    WeatherDatum.where(date: date).each do |weather|
      weather_grid[weather.latitude, weather.longitude] = weather
    end

    weather_grid
  end
end
