class Precip < ApplicationRecord
  # precip units are in mm

  def self.latest_date
    Precip.maximum(:date)
  end

  def self.earliest_date
    Precip.minimum(:date)
  end

  def self.stats(date)
    precips = Precip.where(date: date)

    if precips.size > 0
      data = precips.collect do |precip|
        {
          lat: precip.latitude,
          long: precip.longitude,
          precip: precip.precip
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
    Precip.where(date: date).each do |precip|
      lat = precip.latitude
      long = precip.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = precip.precip.round(2)
    end
    grid
  end

  def self.create_image(date)
    if PrecipDataImport.successful.where(readings_on: date).exists?
      begin
        Rails.logger.info "Precip :: Creating image for #{date}"
        data = land_grid_for_date(date)
        title = "Total daily precip (mm) for #{date.strftime("%b %-d, %Y")}"
        file = image_name(date)
        ImageCreator.create_image(data, title, file, min_value: 0.0)
      rescue => e
        Rails.logger.warn "Precip :: Failed to create image for #{date}: #{e.message}"
        "no_data.png"
      end
    else
      Rails.logger.warn "Precip :: Failed to create image for #{date}: Precip data missing."
      "no_data.png"
    end
  end

  def self.image_name(date)
    "precip_#{date.to_s(:number)}.png"
  end
end
