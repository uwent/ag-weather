class WeatherDatum < ActiveRecord::Base
  def self.land_grid_for_date(date)
    weather_grid = LandGrid.new(WiMn::S_LAT, WiMn::N_LAT, WiMn::E_LONG,
                                WiMn::W_LONG, WiMn::STEP)
    WeatherDatum.where(date: date).each do |weather|
      weather_grid[weather.latitude, weather.longitude] = weather
    end

    weather_grid
  end
end
