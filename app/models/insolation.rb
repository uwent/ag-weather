class Insolation < ApplicationRecord
  def self.land_grid_for_date(date)
    grid = LandGrid.new
    where(date: date).each do |insol|
      lat, long = insol.latitude, insol.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = insol.insolation
    end
    grid
  end

  def self.image_name(date, start_date = nil)
    if start_date.nil?
      "insolation-#{date.to_s(:number)}.png"
    else
      "insolation-#{date.to_s(:number)}-#{start_date.to_s(:number)}.png"
    end
  end

  def self.image_title(date, start_date = nil)
    if start_date.nil?
      "Daily insolation (MJ/day/m2) for #{date.strftime("%-d %B %Y")}"
    else
      fmt = start_date.year != date.year ? "%b %d, %Y" : "%b %d"
      "Total insolation (MJ/m2) for #{start_date.strftime(fmt)} - #{date.strftime("%b %d, %Y")}"
    end
  end

  def self.create_image_data(grid, data)
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = point.insolation
    end
    grid
  end

  def self.create_image(date, start_date: nil)
    if start_date.nil?
      data = where(date: date)
      raise StandardError.new("No data") if data.size == 0
      date = data.distinct.pluck(:date).max
      min = 0
      max = 30
    else
      data = where(date: start_date..date)
      raise StandardError.new("No data") if data.size == 0
      dates = data.distinct.pluck(:date)
      start_date = dates.min
      date = dates.max
      data = data.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(insolation) as insolation")
      min = nil
      max = nil
    end
    title = image_title(date, start_date)
    file = image_name(date, start_date)
    Rails.logger.info "Insolation :: Creating image ==> #{file}"
    grid = create_image_data(LandGrid.new, data)
    ImageCreator.create_image(grid, title, file, min_value: min, max_value: max)
  rescue => e
    Rails.logger.warn "Insolation :: Failed to create image for #{date}: #{e.message}"
    "no_data.png"
  end
end
