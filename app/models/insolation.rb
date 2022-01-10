class Insolation < ApplicationRecord
  UNITS = ["MJ", "KWh"]
  DEFAULT_MAX_MJ = 30
  DEFAULT_MAX_KW = 10

  def self.land_grid_for_date(date)
    grid = LandGrid.new
    where(date:).each do |insol|
      lat, long = insol.latitude, insol.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = insol.insolation
    end
    grid
  end

  def self.create_image(date, start_date: nil, units: "MJ")
    if start_date.nil?
      data = where(date:)
      raise StandardError.new("No data") if data.size == 0
      date = data.distinct.pluck(:date).max
      min = 0
      max = units == "KWh" ? DEFAULT_MAX_KW : DEFAULT_MAX_MJ
    else
      data = where(date: start_date..date)
      raise StandardError.new("No data") if data.size == 0
      dates = data.distinct.pluck(:date)
      start_date = dates.min
      date = dates.max
      data = data.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(insolation) as insolation")
      min = max = nil
    end
    title = image_title(date, start_date, units)
    file = image_name(date, start_date, units)
    Rails.logger.info "Insolation :: Creating image ==> #{file}"
    grid = create_image_data(LandGrid.new, data, units)
    ImageCreator.create_image(grid, title, file, min_value: min, max_value: max)
  rescue => e
    Rails.logger.warn "Insolation :: Failed to create image for #{date}: #{e.message}"
    "no_data.png"
  end

  def self.image_name(date, start_date = nil, units = "MJ")
    name = "insolation-#{units.downcase}-#{date.to_formatted_s(:number)}"
    name += "-#{start_date.to_formatted_s(:number)}" unless start_date.nil?
    name + ".png"
  end

  def self.image_title(date, start_date = nil, units = "MJ")
    if start_date.nil?
      "Daily insolation (#{units}/m2/day) for #{date.strftime("%-d %B %Y")}"
    else
      fmt = start_date.year != date.year ? "%b %d, %Y" : "%b %d"
      "Total insolation (#{units}/m2) for #{start_date.strftime(fmt)} - #{date.strftime("%b %d, %Y")}"
    end
  end

  def self.create_image_data(grid, data, units = "MJ")
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = units == "KWh" ? UnitConverter.mj_to_kwh(point.insolation) : point.insolation
    end
    grid
  end
end
