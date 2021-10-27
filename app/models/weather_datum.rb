class WeatherDatum < ApplicationRecord

  def self.land_grid_for_date(date)
    weather_grid = LandGrid.new
    WeatherDatum.where(date: date).each do |weather|
      weather_grid[weather.latitude, weather.longitude] = weather
    end
    weather_grid
  end

  def self.calculate_all_degree_days_for_date_range(
    lat_range: LandExtent.latitudes,
    long_range: LandExtent.longitudes,
    start_date: Date.current.beginning_of_year,
    end_date: Date.current,
    base: DegreeDaysCalculator::BASE_F,
    upper: DegreeDaysCalculator::UPPER_F,
    method: DegreeDaysCalculator::METHOD,
    in_f: true
  )

    WeatherDatum.where(date: start_date..end_date)
    .where(latitude: lat_range, longitude: long_range)
    .each_with_object(Hash.new(0)) do |weather, hash|
      coord = [weather.latitude, weather.longitude]
      if hash[coord].nil?
        hash[coord] = weather.degree_days(base, upper, method)
      else
        hash[coord] += weather.degree_days(base, upper, method)
      end
      hash
    end
  end

  def self.land_grid_since(date)
    grid = LandGrid.new

    WeatherDatum.where("date >= ?", date).each do |weather|
      if grid[weather.latitude, weather.longitude].nil?
        grid[weather.latitude, weather.longitude] = [weather]
      else
        grid[weather.latitude, weather.longitude] << weather
      end
    end
    grid
  end

  def self.calculate_all_degree_days(
    date,
    base: DegreeDaysCalculator::BASE_F,
    upper: DegreeDaysCalculator::UPPER_F,
    method: DegreeDaysCalculator::METHOD
  )
    temp_grid = land_grid_since(date)
    degree_day_grid = LandGrid.new
    LandExtent.each_point do |lat, long|
      next if temp_grid[lat,long].nil?
      dd = temp_grid[lat, long].collect do |weather_day|
        weather_day.degree_days(method, base, upper)
      end.sum
      degree_day_grid[lat, long] = dd
    end
    degree_day_grid
  end

  # fahrenheit min/max. base/upper must be F
  def degree_days(base, upper, method = DegreeDaysCalculator::METHOD, in_f = true)
    min = in_f ? DegreeDaysCalculator.c_to_f(min_temperature) : min_temperature
    max = in_f ? DegreeDaysCalculator.c_to_f(max_temperature) : max_temperature
    DegreeDaysCalculator.calculate(min, max, base: base, upper: upper, method: method)
  end

  # Image creator
  def self.create_image(date)
    if WeatherDataImport.successful.where(readings_on: date).exists?
      begin
        Rails.logger.info "WeatherDatum :: Creating image for #{date}"
        data = create_image_data_grid(date)
        title = "Mean daily temperature (F) for #{date.strftime('%-d %B %Y')}"
        ImageCreator.create_image(data, title, image_name(date))
      rescue => e
        Rails.logger.warn "WeatherDatum :: Failed to create image for #{date}: #{e.message}"
        return "no_data.png"
      end
    else
      Rails.logger.warn "WeatherDatum :: Failed to create image for #{date}: weather data missing"
      return "no_data.png"
    end
  end

  def self.image_name(date)
    "mean_temp_#{date.to_s(:number)}.png"
  end

  def self.create_image_data_grid(date)
    grid = LandGrid.new
    WeatherDatum.where(date: date).each do |wd|
      lat, long = wd.latitude, wd.longitude
      next unless grid.inside?(lat, long)
      mean_temp_c = (wd.min_temperature + wd.max_temperature) / 2.0
      mean_temp_f = DegreeDaysCalculator.c_to_f(mean_temp_c)
      grid[lat, long] = mean_temp_f.round(2)
    end
    grid
  end

  def self.latest_date
    WeatherDatum.maximum(:date)
  end

  def self.earliest_date
    WeatherDatum.minimum(:date)
  end

end
