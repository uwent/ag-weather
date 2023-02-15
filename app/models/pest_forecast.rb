class PestForecast < ApplicationRecord
  extend PestModels

  MAP_DIR = "pest_maps"

  def self.pest_names
    {
      potato_blight_dsv: "Late blight DSV",
      potato_p_days: "Early blight P-Day",
      carrot_foliar_dsv: "Carrot foliar disease DSV",
      cercospora_div: "Cercospora leaf spot DSV",
      botcast_dsi: "Botrytis botcast DSI"
    }.freeze
  end

  def self.pests
    pest_names.keys.map(&:to_s).freeze
  end

  def self.new_from_weather(weather)
    new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_late_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      botcast_dsi: compute_botcast_dsi(weather)
    )
  end

  def self.create_images
    pests.each do |pest|
      create_image(pest)
    end
  end

  def self.create_image(
    pest = "potato_blight_dsv",
    start_date: latest_date - 1.week,
    end_date: latest_date,
    min_value: nil,
    max_value: nil,
    extent: "all"
  )

    raise ArgumentError.new("Invalid pest!") unless pests.include? pest

    start_date = start_date.to_date
    end_date = end_date.to_date

    pfs = where(date: start_date..end_date)
    min_date = pfs.minimum(:date)
    max_date = pfs.maximum(:date)
    totals = pfs.grid_summarize("sum(#{pest}) as total")
    grid = (extent == "wi") ? LandGrid.wisconsin_grid : LandGrid.new

    totals.each do |pf|
      lat, long = pf.latitude, pf.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = pf.total
    end

    tick = (grid.max / 10.0).ceil
    if min_value || max_value
      min_value ||= 0
      max_value ||= tick * 10
      title, file = image_attr(pest, start_date, end_date, min_value, max_value, extent)
    else
      title, file = image_attr(pest, start_date, end_date, min_value, max_value, extent)
      min_value = 0
      max_value = tick * 10
    end

    Rails.logger.info "#{name} :: Creating #{pest} image for #{start_date} - #{end_date}"
    ImageCreator.create_image(grid, title, file, subdir: MAP_DIR, min_value:, max_value:)
  rescue => e
    Rails.logger.warn "#{name} :: Failed to create image for #{pest}: #{e.message}"
    nil
  end

  def self.image_attr(pest, start_date, end_date, min_value, max_value, extent)
    pest_name = pest_names[pest.to_sym]
    fmt2 = "%b %-d, %Y"
    fmt1 = (start_date.year != end_date.year) ? fmt2 : "%b %-d"
    title = pest_name + " accumulation from #{start_date.strftime(fmt1)} - #{end_date.strftime(fmt2)}"
    file = "dsv-totals-for-#{pest_name.tr(" ", "-").downcase}-from-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if extent == "wi"
    file += ".png"
    [title, file]
  end
end
