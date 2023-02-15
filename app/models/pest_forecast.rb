class PestForecast < ApplicationRecord
  extend PestModels

  MAP_DIR = "pest_maps"

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

  def self.pest_titles
    {
      potato_blight_dsv: "Late blight DSV",
      potato_p_days: "Early blight P-Day",
      carrot_foliar_dsv: "Carrot foliar disease DSV",
      cercospora_div: "Cercospora leaf spot DSV",
      botcast_dsi: "Botrytis botcast DSI"
    }.freeze
  end

  def self.pest_models
    %w[potato_blight_dsv potato_p_days carrot_foliar_dsv cercospora_div botcast_dsi]
  end

  def self.create_pest_maps
    pest_models.each do |model|
      create_pest_map(model)
    end
  end

  def self.create_pest_map(pest, start_date = latest_date - 1.week, end_date = latest_date, min_value = nil, max_value = nil, wi_only = false)
    raise ArgumentError.new("Invalid pest!") unless pest_models.include? pest

    forecasts = where(date: start_date..end_date)

    if forecasts.size > 0
      dates = forecasts.distinct.pluck(:date)
      start_date, end_date = dates.min, dates.max

      grid = wi_only ? LandGrid.wisconsin_grid : LandGrid.new
      totals = forecasts.group(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(#{pest}) as total")

      totals.each do |pf|
        lat, long = pf.latitude, pf.longitude
        next unless grid.inside?(lat, long)
        grid[lat, long] = pf.total
      end

      tick = (grid.max / 10.0).ceil
      if min_value || max_value
        min_value ||= 0
        max_value ||= tick * 10
        title, file = pest_map_attr(pest, start_date, end_date, min_value, max_value, wi_only)
      else
        title, file = pest_map_attr(pest, start_date, end_date, min_value, max_value, wi_only)
        min_value = 0
        max_value = tick * 10
      end

      Rails.logger.info "PestForecast :: Creating #{pest} image for #{start_date} - #{end_date}"
      ImageCreator.create_image(grid, title, file, subdir: MAP_DIR, min_value:, max_value:)
    else
      Rails.logger.warn "PestForecast :: Failed to create image for #{pest}: No data"
      "no_data.png"
    end
  end

  def self.pest_map_attr(pest, start_date, end_date, min_value, max_value, wi_only)
    pest_title = pest_titles[pest.to_sym]
    fmt2 = "%b %-d, %Y"
    fmt1 = (start_date.year != end_date.year) ? fmt2 : "%b %-d"
    title = pest_title + " accumulation from #{start_date.strftime(fmt1)} - #{end_date.strftime(fmt2)}"
    file = "dsv-totals-for-#{pest_title.tr(" ", "-").downcase}-from-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if wi_only
    file += ".png"
    [title, file]
  end
end
