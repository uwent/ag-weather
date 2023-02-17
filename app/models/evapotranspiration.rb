class Evapotranspiration < ApplicationRecord

  IMAGE_SUBDIR = "et"

  def self.valid_units
    ["in", "mm"].freeze
  end

  # def has_required_data?
  #   weather && insolation
  # end

  # def weather
  #   @weather ||= WeatherDatum.find_by(latitude:, longitude:, date:)
  # end

  # def insolation
  #   @insolation ||= Insolation.find_by(latitude:, longitude:, date:)
  # end

  # def already_calculated?
  #   Evapotranspiration.find_by(latitude:, longitude:, date:)
  # end

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
    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = point.potential_et
    end
    grid
  end

  def self.image_path(filename)
    File.join(ImageCreator.file_dir, IMAGE_SUBDIR, filename)
  end

  def self.image_url(filename)
    File.join(ImageCreator.url_path, IMAGE_SUBDIR, filename)
  end

  def self.create_image(
    start_date: nil,
    end_date: latest_date,
    units: "in",
    extent: nil
  )
    raise ArgumentError.new("Invalid units!") unless valid_units.include?(units)

    if start_date
      data = where(date: start_date..end_date)
      min_date = data.minimum(:date)
      max_date = data.maximum(:date)
      attrs = {start_date: min_date, end_date: max_date, units:, extent:}
    else
      data = where(date: end_date)
      attrs = {end_date:, units:, extent:}
    end

    raise StandardError.new("No data") unless data.exists?

    file, title = image_attr(**attrs)
    Rails.logger.info "#{name} :: Creating image ==> #{file}"

    grid = (extent == "wi") ? LandGrid.wisconsin_grid : LandGrid.new
    totals = data.grid_summarize("sum(potential_et) as total")
    totals.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = (units == "in") ? point.total : UnitConverter.in_to_mm(point.total)
    end

    # gnuplot scale bar range
    if start_date
      min_value = max_value = nil
    else
      min_value = 0
      max_value = (units == "mm") ? 8 : 0.3 # image scale bar maximum
    end

    ImageCreator.create_image(grid, title, file, subdir: IMAGE_SUBDIR, min_value:, max_value:)
  rescue => e
    Rails.logger.error "#{name} :: Failed to create image for #{end_date}: #{e.message}"
    nil
  end

  def self.image_attr(start_date: nil, end_date:, units: "in", extent: nil, min_value: nil, max_value: nil)
    title = if start_date.nil?
      "Potential evapotranspiration (#{units}/day) for #{end_date.strftime("%b %-d, %Y")}"
    else
      fmt1 = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      "Potential evapotranspiration (total #{units}) for #{start_date.strftime(fmt1)} - #{end_date.strftime("%b %-d, %Y")}"
    end

    file = "evapo-#{units}"
    file += "-#{start_date.to_formatted_s(:number)}" unless start_date.nil?
    file += "-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if extent == "wi"
    file += ".png"

    [file, title]
  end
end
