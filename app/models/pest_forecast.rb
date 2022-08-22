class PestForecast < ApplicationRecord
  extend PestModels

  NO_MAX = 150

  def self.pest_map_dir
    "pest_maps"
  end

  def self.dd_map_dir
    "dd_maps"
  end

  def self.for_lat_long_date_range(lat, long, start_date, end_date)
    where(latitude: lat)
      .where(longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date)
      .order(date: :desc)
  end

  # degree days in F
  def self.new_from_weather(weather)
    new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_late_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      botcast_dsi: compute_botcast_dsi(weather),
      dd_32_none: weather.degree_days(32, NO_MAX), # 0 / none C
      dd_38_75: weather.degree_days(38, 75), # 3.3 C / 23.9 C
      dd_39p2_86: weather.degree_days(39.2, 86), # 4 / 30 C
      dd_41_86: weather.degree_days(41, 86), # 5 / 30 C
      dd_41_88: weather.degree_days(41, 88), # 5 / 31 C
      dd_41_none: weather.degree_days(41, NO_MAX), # 5 / none C
      dd_42p8_86: weather.degree_days(42.8, 86), # 6 / 30 C
      dd_45_86: weather.degree_days(45, 86), # 7.2 / 30 C
      dd_45_none: weather.degree_days(45, NO_MAX), # 7.2 / none C
      dd_48_none: weather.degree_days(48, NO_MAX), # 9 / none C
      dd_50_86: weather.degree_days(50, 86), # 10 / 30 C
      dd_50_88: weather.degree_days(50, 88), # 10 / 31.1 C
      dd_50_90: weather.degree_days(50, 90), # 10 / 32.2 C
      dd_50_none: weather.degree_days(50, NO_MAX), # 10 / none C
      dd_52_none: weather.degree_days(52, NO_MAX), # 11.1 / none C
      dd_54_92: weather.degree_days(54, 92), # 12.2 / 33.3 C
      dd_55_92: weather.degree_days(55, 92), # 12.8 / 33.3 C
      frost: weather.min_temperature < 0,
      freeze: weather.min_temperature < -2.22
    )
  end

  def self.pest_titles
    {
      potato_blight_dsv: "Late blight DSV",
      potato_p_days: "Early blight P-Day",
      carrot_foliar_dsv: "Carrot foliar disease DSV",
      cercospora_div: "Cercospora leaf spot DSV",
      botcast_dsi: "Botrytis botcast DSI",
      dd_39p2_86: "Fahrenheit degree days (base 39F, upper 86F)",
      dd_41_86: "Fahrenheit degree days (base 41F, upper 86F)",
      dd_41_88: "Fahrenheit degree days (base 41F, upper 88F)",
      dd_41_none: "Fahrenheit degree days (base 41F)",
      dd_42p8_86: "Fahrenheit degree days (base 42.8F, upper 86F)",
      dd_45_none: "Fahrenheit degree days (base 45F)",
      dd_45_86: "Fahrenheit degree days (base 45F, upper 86F)",
      dd_48_none: "Fahrenheit degree days (base 48F)",
      dd_50_86: "Fahrenheit degree days (base 50F, upper 86F)",
      dd_50_88: "Fahrenheit degree days (base 50F, upper 88F)",
      dd_50_90: "Fahrenheit degree days (base 50F, upper 90F)",
      dd_50_none: "Fahrenheit degree days (base 50F)",
      dd_52_none: "Fahrenheit degree days (base 52F)",
      dd_54_92: "Fahrenheit degree days (base 54F, upper 92F)",
      dd_55_92: "Fahrenheit degree days (base 55F, upper 92F)",
      frost: "Frost (min temperature < 32F)",
      freeze: "Freeze (min temperature < 28F)"
    }
  end

  def self.pest_models
    %w[potato_blight_dsv potato_p_days carrot_foliar_dsv cercospora_div botcast_dsi]
  end

  def self.dd_models
    column_names.select { |c| c.include? "dd_" }
  end

  def self.all_models
    pest_models.concat dd_models
  end

  def self.create_pest_maps
    pest_models.each do |model|
      create_pest_map(model)
    end
  end

  def self.create_dd_maps
    dd_models.each do |model|
      create_dd_map(model)
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
        .order(:latitude, :longitude)
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
      ImageCreator.create_image(grid, title, file, subdir: pest_map_dir, min_value:, max_value:)
    else
      Rails.logger.warn "PestForecast :: Failed to create image for #{pest}: No data"
      "no_data.png"
    end
  end

  def self.pest_map_attr(pest, start_date, end_date, min_value, max_value, wi_only)
    pest_title = pest_titles[pest.to_sym]
    fmt2 = "%b %-d, %Y"
    fmt1 = start_date.year != end_date.year ? fmt2 : "%b %-d"
    title = pest_title + " accumulation from #{start_date.strftime(fmt1)} - #{end_date.strftime(fmt2)}"
    file = "dsv-totals-for-#{pest_title.tr(" ", "-").downcase}-from-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if wi_only
    file += ".png"
    [title, file]
  end

  def self.create_dd_map(model, start_date = latest_date.beginning_of_year, end_date = latest_date, units = "F", min_value = nil, max_value = nil, wi_only = false)
    raise ArgumentError.new("Invalid model!") unless dd_models.include? model
    raise ArgumentError.new("Invalid units!") unless ["F", "C"].include? units

    forecasts = where(date: start_date..end_date)
    if forecasts.size > 0
      dates = forecasts.distinct.pluck(:date)
      start_date, end_date = dates.min, dates.max

      grid = wi_only ? LandGrid.wisconsin_grid : LandGrid.new
      totals = forecasts.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(#{model}) as total")

      totals.each do |pf|
        lat, long = pf.latitude, pf.longitude
        next unless grid.inside?(lat, long)
        grid[lat, long] = units == "F" ? pf.total : UnitConverter.fdd_to_cdd(pf.total)
      end

      # define map scale by rounding the interval up to divisible by 5
      tick = ((grid.max / 10.0) / 5.0).ceil * 5.0
      if min_value || max_value
        min_value ||= 0
        max_value ||= tick * 10
        title, file = dd_map_attr(model, start_date, end_date, units, min_value, max_value, wi_only)
      else
        title, file = dd_map_attr(model, start_date, end_date, units, min_value, max_value, wi_only)
        min_value = 0
        max_value = tick * 10
      end

      Rails.logger.info "PestForecast :: Creating #{model} image for #{start_date} - #{end_date}"
      ImageCreator.create_image(grid, title, file, subdir: pest_map_dir, min_value:, max_value:)
    else
      Rails.logger.warn "PestForecast :: Failed to create image for #{model}: No data"
      "no_data.png"
    end
  end

  def self.dd_map_attr(model, start_date, end_date, units, min_value, max_value, wi_only)
    _, base, upper = model.tr("p", ".").split("_")
    if units == "C"
      base = "%g" % ("%.1f" % UnitConverter.f_to_c(base.to_f))
      upper = "%g" % ("%.1f" % UnitConverter.f_to_c(upper.to_f)) unless upper == "none"
    end
    model_name = "base #{base}°#{units}"
    model_name += ", upper #{upper}°#{units}" unless upper == "none"
    fmt2 = "%b %-d, %Y"
    fmt1 = start_date.year != end_date.year ? fmt2 : "%b %-d"
    title = "Degree day totals for #{model_name} from #{start_date.strftime(fmt1)} - #{end_date.strftime(fmt2)}"
    file = "#{units.downcase}dd-totals-for-#{model_name.tr(",°", "").tr(" ", "-").downcase}-from-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if wi_only
    file += ".png"
    [title, file, base, upper]
  end
end
