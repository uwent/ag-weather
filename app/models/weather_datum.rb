class WeatherDatum < ActiveRecord::Base
  def self.land_grid_for_date(date)
    weather_grid = LandGrid.wisconsin_grid

    WeatherDatum.where(date: date).each do |weather|
      weather_grid[weather.latitude, weather.longitude] = weather
    end

    weather_grid
  end

  def self.calculate_all_degree_days_for_date_range(method,
                                                    start_date,
                                                    end_date,
                                                    base = DegreeDaysCalculator::DEFAULT_BASE,
                                                    upper = PestForecast::NO_MAX)

    results = []
    grid = LandGrid.wisconsin_grid
    weatherDatum = WeatherDatum.where(date: start_date..end_date)
    weatherDatum.each do |weather|
      if grid[weather.latitude, weather.longitude].nil?
        grid[weather.latitude, weather.longitude] = weather.degree_days(method, base, upper)
      else
        grid[weather.latitude, weather.longitude] += weather.degree_days(method, base, upper)
      end
    end
    grid
  end

  def self.land_grid_since(date)
    grid = LandGrid.wisconsin_grid

    WeatherDatum.where('date >= ?', date).each do |weather|
      if grid[weather.latitude, weather.longitude].nil?
        grid[weather.latitude, weather.longitude] = [weather]
      else
        grid[weather.latitude, weather.longitude] << weather
      end
    end
    grid
  end

  def self.calculate_all_degree_days(method, date,
                                     base = DegreeDaysCalculator::DEFAULT_BASE,
                                     upper = DegreeDaysCalculator::DEFAULT_UPPER)
    temp_grid = land_grid_since(date)
    degree_day_grid = LandGrid.wisconsin_grid
    Wisconsin.each_point do |lat, long|
      next if temp_grid[lat,long].nil?
      dd = temp_grid[lat, long].collect do |weather_day|
        weather_day.degree_days(method, base, upper)
      end.sum
      degree_day_grid[lat, long] = dd
    end
    degree_day_grid
  end

  def degree_days(method, base, upper)
    base ||= DegreeDaysCalculator::DEFAULT_BASE
    upper ||= DegreeDaysCalculator::DEFAULT_UPPER
    val = DegreeDaysCalculator.calculate(method,
       DegreeDaysCalculator.to_fahrenheit(min_temperature),
       DegreeDaysCalculator.to_fahrenheit(max_temperature),
                                   base, upper)
    val
  end
end
