class Insolation < ApplicationRecord

  IMAGE_SUBDIR = "insol"

  # per day per m^2
  # stored in MJ, divide by 3.6 to convert to KWh
  def self.valid_units
    ["MJ", "KWh"].freeze
  end

  def self.land_grid_for_date(date:, grid: LandGrid.new, units: "MJ")
    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = convert(point.insolation, units)
    end
    grid
  end

  def self.hash_grid_for_date(date:, units: "MJ")
    grid = {}
    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      grid[[lat, long]] = convert(point.insolation, units)
    end
    grid
  end

  def self.cumulative_land_grid(
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    grid: LandGrid.new,
    units: "MJ")

    data = where(date: start_date..end_date).grid_summarize("sum(insolation) as total")
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = convert(point.total, units)
    end
    grid
  end

  def self.cumulative_hash_grid(
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    units: "MJ"
  )
    grid = {}
    data = where(date: start_date..end_date).grid_summarize("sum(insolation) as total")
    data.each do |point|
      lat, long = point.latitude, point.longitude
      grid[[lat, long]] = convert(point.total, units)
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
    units: "MJ",
    min_value: nil,
    max_value: nil,
    extent: nil)

    raise ArgumentError.new("Invalid units!") unless valid_units.include?(units)

    grid = (extent == "wi") ? LandGrid.wisconsin_grid : LandGrid.new

    if start_date.nil?
      data = land_grid_for_date(date: end_date, grid:, units:)
      min = 0
      max = (units == "KWh") ? 10 : 30 # image scale bar maximum depending on units
    else
      data = cumulative_land_grid(start_date:, end_date:, grid:, units:)
      insols = where(date: start_date..end_date, latitude: grid.latitudes.min, longitude: grid.longitudes.min)
      start_date = insols.minimum(:date)
      end_date = insols.maximum(:date)
      min = max = nil
    end

    raise StandardError.new("No data") if data.empty?

    file, title = image_attr(start_date:, end_date:, units:, extent:)
    Rails.logger.info "Insolation :: Creating image ==> #{file}"
    ImageCreator.create_image(data, title, file, subdir: IMAGE_SUBDIR, min_value: min, max_value: max)
  rescue => e
    Rails.logger.error "#{name} :: Failed to create image for #{end_date}: #{e.message}"
    nil
  end

  def self.image_attr(start_date: nil, end_date:, units: "MJ", extent: nil, min_value: nil, max_value: nil)
    title = if start_date.nil?
      "Daily insolation (#{units}/m2/day) for #{end_date.strftime("%-d %B %Y")}"
    else
      fmt = (start_date.year != date.year) ? "%b %-d, %Y" : "%b %-d"
      "Total insolation (#{units}/m2) for #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    end

    file = "insolation-#{units.downcase}"
    file += "-#{start_date.to_formatted_s(:number)}" unless start_date.nil?
    file += "-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if extent == "wi"
    file += ".png"

    [file, title]
  end

  # value stored in MJ, convert if "KWh" requested
  def self.convert(value, units)
    (units == "KWh") ? UnitConverter.mj_to_kwh(value) : value
  end
end
