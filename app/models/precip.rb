class Precip < ApplicationRecord
  # precip units are in mm

  UNITS = ["in", "mm"]

  def self.stats(date)
    precips = where(date:)

    if precips.size > 0
      data = precips.collect do |point|
        {
          lat: point.latitude,
          long: point.longitude,
          precip: point.precip
        }
      end

      precips = data.map { |d| d[:precip] }
      pos_precips = precips.find_all { |n| n > 0 }

      pts = precips.size
      pts_precip = pos_precips.size
      precip_pct = (pts_precip.to_f / pts * 100).round(1)
      mean_precip = pos_precips.sum(0.0) / pts_precip
      max_precip = pos_precips.max

      puts "Precip stats for #{date}:"
      puts "Total points: #{precips.size}"
      puts "Points with precip: #{pts_precip} (#{precip_pct}%)"
      puts "Mean precip: #{mean_precip.round(3)} mm"
      puts "Max precip: #{max_precip} mm"
    else
      puts "No precip data for #{date}"
    end
  end

  def self.land_grid_for_date(date)
    grid = LandGrid.new
    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = point.precip
    end
    grid
  end

  def self.image_name(date, start_date = nil, units = UNITS[0])
    name = "precip-#{units}-#{date.to_formatted_s(:number)}"
    name += "-#{start_date.to_formatted_s(:number)}" unless start_date.nil?
    name + ".png"
  end

  def self.image_title(date, start_date = nil, units = UNITS[0])
    if start_date.nil?
      "Total daily precip (#{units}) for #{date.strftime("%b %-d, %Y")}"
    else
      fmt = (start_date.year != date.year) ? "%b %-d, %Y" : "%b %-d"
      "Total cumulative precip (#{units}) for #{start_date.strftime(fmt)} - #{date.strftime("%b %-d, %Y")}"
    end
  end

  def self.create_image_data(grid, data, units = UNITS[0])
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = (units == "in") ? UnitConverter.mm_to_in(point.precip) : point.precip
    end
    grid
  end

  def self.create_image(date, start_date: nil, units: UNITS[0])
    if start_date.nil?
      precips = where(date:)
      raise StandardError.new("No data") if precips.size == 0
      date = precips.distinct.pluck(:date).max
    else
      precips = where(date: start_date..date)
      raise StandardError.new("No data") if precips.size == 0
      start_date = precips.distinct.pluck(:date).min
      date = precips.distinct.pluck(:date).max
      precips = precips.group(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(precip) as precip")
    end
    title = image_title(date, start_date, units)
    file = image_name(date, start_date, units)
    Rails.logger.info "Precip :: Creating image ==> #{file}"
    grid = create_image_data(LandGrid.new, precips, units)
    ImageCreator.create_image(grid, title, file, min_value: 0.0)
  rescue => e
    Rails.logger.warn "Precip :: Failed to create image for #{date}: #{e.message}"
    "no_data.png"
  end
end
