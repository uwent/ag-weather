class WeatherDatum < ApplicationRecord

  # def weather
  #   @weather ||= WeatherDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  # end

  def self.land_grid_for_date(grid, date)
    # grid = LandGrid.weather_grid

    WeatherDatum.where(date: date).each do |weather|
      grid[weather.latitude, weather.longitude] = weather
    end

    grid
  end

  def self.calculate_all_degree_days_for_date_range(
    method,
    start_date,
    end_date,
    base = DegreeDaysCalculator::DEFAULT_BASE,
    upper = PestForecast::NO_MAX
  )
    WeatherDatum.where(date: start_date..end_date)
    # .where(latitude: WeatherExtent.latitudes, longitude: WeatherExtent.longitudes)
    .each_with_object(Hash.new(0)) do |weather_datum, hash|
      coordinate = [weather_datum.latitude.to_f, weather_datum.longitude.to_f]
      if hash[coordinate].nil?
        hash[coordinate] = weather_datum.degree_days(method, base, upper)
      else
        hash[coordinate] += weather_datum.degree_days(method, base, upper)
      end
      hash
    end
  end

  def self.land_grid_since(grid, date)
    # grid = LandGrid.new

    WeatherDatum.where('date >= ?', date).each do |weather|
      if grid[weather.latitude, weather.longitude].nil?
        grid[weather.latitude, weather.longitude] = [weather]
      else
        grid[weather.latitude, weather.longitude] << weather
      end
    end
    grid
  end

  def self.calculate_all_degree_days(
    grid,
    date,
    method,
    base = DegreeDaysCalculator::DEFAULT_BASE,
    upper = DegreeDaysCalculator::DEFAULT_UPPER
  )
    temp_grid = land_grid_since(grid, date)
    # degree_day_grid = LandGrid.weather_grid
    grid.each_point do |lat, long|
      next if temp_grid[lat,long].nil?
      dd = temp_grid[lat, long].collect do |weather_day|
        weather_day.degree_days(method, base, upper)
      end.sum
      grid[lat, long] = dd
    end
    grid
  end

  def degree_days(method, base, upper)
    base ||= DegreeDaysCalculator::DEFAULT_BASE
    upper ||= DegreeDaysCalculator::DEFAULT_UPPER
    DegreeDaysCalculator.calculate(
      method,
      DegreeDaysCalculator.to_fahrenheit(min_temperature),
      DegreeDaysCalculator.to_fahrenheit(max_temperature),
      base,
      upper
    )
  end

end
