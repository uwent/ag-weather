class WeatherDatum < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.col_names
    {
      min_temperature: "Min air temp", # C
      avg_temperature: "Avg air temp", # C
      max_temperature: "Max air temp", # C
      vapor_pressure: "Vapor pressure", # kPa
      dew_point: "Dew point", # C
      frost: "Frost days", # number of days < 0 C
      freezing: "Freezing days" # number of days < 2 C
    }
  end

  def self.default_col
    :avg_temperature
  end

  def self.default_stat
    :avg
  end

  def self.valid_units
    ["C", "F"].freeze
  end

  def self.convert(value, units)
    (units == "F") ? UnitConverter.c_to_f(value) : value
  end

  def self.image_subdir
    "weather"
  end

  def self.image_name_prefix(col:, stat: nil, **args)
    str = col_names[col.to_sym]
    str = str.downcase.tr(" ", "-")
    "#{stat.to_s}-#{str}" if stat
  rescue
    "weather"
  end

  def self.image_title(
    col:,
    date: nil,
    start_date: nil,
    end_date: nil,
    units: valid_units[0],
    stat: nil,
    **args)

    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date

    title = col_names[col.to_sym]
    title = "#{stat.to_s.humanize} #{title.downcase}" if stat
    title += " (#{units}) "
    if start_date
      fmt = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      title += "from #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    else
      title += "on #{end_date.strftime("%b %-d, %Y")}"
    end
    title
  end

  # def self.calculate_all_degree_days_for_date_range(
  #   lat_range: LandExtent.latitudes,
  #   long_range: LandExtent.longitudes,
  #   start_date: Date.current.beginning_of_year,
  #   end_date: Date.current,
  #   base: DegreeDaysCalculator::BASE_F,
  #   upper: DegreeDaysCalculator::UPPER_F,
  #   method: DegreeDaysCalculator::METHOD,
  #   in_f: true
  # )

  #   where(date: start_date..end_date)
  #     .where(latitude: lat_range, longitude: long_range)
  #     .each_with_object(Hash.new(0)) do |weather, hash|
  #     coord = [weather.latitude, weather.longitude]
  #     if hash[coord].nil?
  #       hash[coord] = weather.degree_days(base, upper, method)
  #     else
  #       hash[coord] += weather.degree_days(base, upper, method)
  #     end
  #     hash
  #   end
  # end

  # def self.land_grid_since(date)
  #   grid = LandGrid.new
  #   where("date >= ?", date).each do |w|
  #     lat, long = w.latitude, w.longitude
  #     if grid[lat, long].nil?
  #       grid[lat, long] = [w]
  #     else
  #       grid[lat, long] << w
  #     end
  #   end
  #   grid
  # end

  # Calculates degree days for land grid since date
  # def self.calculate_all_degree_days(
  #   date,
  #   base: DegreeDaysCalculator::BASE_F,
  #   upper: DegreeDaysCalculator::UPPER_F,
  #   method: DegreeDaysCalculator::METHOD
  # )
  #   temp_grid = land_grid_since(date)
  #   dd_grid = LandGrid.new
  #   LandExtent.each_point do |lat, long|
  #     next if temp_grid[lat, long].nil?
  #     dd = temp_grid[lat, long].collect do |w|
  #       w.degree_days(base, upper, method)
  #     end.sum(0)
  #     dd_grid[lat, long] = dd
  #   end
  #   dd_grid
  # end

  # def self.land_grid_for_date(date)
  #   grid = LandGrid.new
  #   where(date:).each do |w|
  #     lat, long = w.latitude, w.longitude
  #     next unless grid.inside?(lat, long)
  #     grid[lat, long] = w
  #   end
  #   grid
  # end

  # fahrenheit min/max. base/upper must be F
  def degree_days(base, upper = 150, method = DegreeDaysCalculator::METHOD, in_f = true)
    min = in_f ? UnitConverter.c_to_f(min_temperature) : min_temperature
    max = in_f ? UnitConverter.c_to_f(max_temperature) : max_temperature
    dd = DegreeDaysCalculator.calculate(min, max, base:, upper:, method:)
    [0, dd].max unless dd.nil?
  end
end
