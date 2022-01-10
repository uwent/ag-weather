class Evapotranspiration < ApplicationRecord
  UNITS = ["in", "mm"]
  DEFAULT_MAX_IN = 0.25
  DEFAULT_MAX_MM = 6.5

  def has_required_data?
    weather && insolation
  end

  def weather
    @weather ||= WeatherDatum.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def insolation
    @insolation ||= Insolation.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def already_calculated?
    Evapotranspiration.find_by(latitude: latitude, longitude: longitude, date: date)
  end

  def calculate_et(insolation, weather)
    EvapotranspirationCalculator.et(
      weather.avg_temperature,
      weather.vapor_pressure,
      insolation,
      date.yday,
      latitude
    )
  end

  def self.land_grid_for_date(date)
    grid = LandGrid.new
    where(date: date).each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = point.potential_et
    end
    grid
  end

  def self.create_image(date, start_date: nil, units: "in")
    if start_date.nil?
      ets = where(date: date)
      raise StandardError.new("No data") if ets.size == 0
      date = ets.distinct.pluck(:date).max
      min = 0
      max = units == "mm" ? DEFAULT_MAX_MM : DEFAULT_MAX_IN
    else
      ets = where(date: start_date..date)
      raise StandardError.new("No data") if ets.size == 0
      start_date = ets.distinct.pluck(:date).min
      date = ets.distinct.pluck(:date).max
      ets = ets.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(potential_et) as potential_et")
      min = max = nil
    end
    title = image_title(date, start_date, units)
    file = image_name(date, start_date, units)
    Rails.logger.info "Evapotranspiration :: Creating image ==> #{file}"
    grid = create_image_data(LandGrid.new, ets, units)
    ImageCreator.create_image(grid, title, file, min_value: min, max_value: max)
  rescue => e
    Rails.logger.warn "Evapotranspiration :: Failed to create image for #{date}: #{e.message}"
    "no_data.png"
  end

  def self.image_name(date, start_date = nil, units = "in")
    name = "evapo-#{units}-#{date.to_formatted_s(:number)}"
    name += "-#{start_date.to_formatted_s(:number)}" unless start_date.nil?
    name + ".png"
  end

  def self.image_title(date, start_date = nil, units = "in")
    if start_date.nil?
      "Potential evapotranspiration (#{units}/day) for #{date.strftime("%b %-d, %Y")}"
    else
      fmt = start_date.year != date.year ? "%b %d, %Y" : "%b %d"
      "Potential evapotranspiration (total #{units}) for #{start_date.strftime(fmt)} - #{date.strftime("%b %d, %Y")}"
    end
  end

  def self.create_image_data(grid, query, units = "in")
    query.each do |et|
      lat, long = et.latitude, et.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = units == "mm" ? UnitConverter.in_to_mm(et.potential_et) : et.potential_et
    end
    grid
  end
end
