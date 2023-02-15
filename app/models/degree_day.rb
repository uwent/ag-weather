class DegreeDay < ApplicationRecord
  MAP_DIR = "dd_maps"
  
  def self.models
    %i[
      dd_32
      dd_38_75
      dd_39p2_86
      dd_41
      dd_41_86
      dd_42p8_86
      dd_45
      dd_45_80p1
      dd_45_86
      dd_48
      dd_50
      dd_50_86
      dd_50_87p8
      dd_50_90
      dd_52
      dd_52_86
      dd_55_92
    ].freeze
  end

  def self.model_names
    models.map(&:to_s)
  end

  def self.on(date)
    where(date:)
  end

  def self.daily
    where(cumulative: false)
  end

  def self.cumulative
    where(cumulative: true)
  end

  def self.new_from_weather(w)
    new(
      date: w.date,
      latitude: w.latitude,
      longitude: w.longitude,

      dd_32: w.degree_days(32), # 0 C
        # nothing yet

      dd_38_75: w.degree_days(38, 75), # 3.3 C / 23.9 C
        # nothing yet

      dd_39p2_86: w.degree_days(39.2, 86), # 4 / 30 C
        # aphids
        # onion maggot
        # seedcorn maggot

      dd_41: w.degree_days(41), # 5 C
        # flea beetle
        # oak wilt vectors

      dd_41_86: w.degree_days(41, 86), # 5 / 30 C
        # stalk borer

      dd_42p8_86: w.degree_days(42.8, 86), # 6 / 30 C
        # cabbage maggot

      dd_45: w.degree_days(45), # 7.2 C
        # western flower thrips

      dd_45_80p1: w.degree_days(45, 80.1), # 7.2 / 26.7
        # variegated cutworm

      dd_45_86: w.degree_days(45, 86), # 7.2 / 30 C
        # spotted wing drosophila

      dd_48: w.degree_days(48), # 9 C
        # alfalfa weevil

      dd_50: w.degree_days(50), # 10 C
        # BMSB (dubious)
        # flea beetle (crucifer)
        # imported cabbageworm
        # japanese beetle
        # mint root borer
        # squash vine borer
        # western bean cutworm

      dd_50_86: w.degree_days(50, 86), # 10 / 30 C
        # asparagus beetle (common)
        # black cutworm
        # european corn borer

      dd_50_87p8: w.degree_days(50, 87.8), # 10 / 31 C
        # no insect model

      dd_50_90: w.degree_days(50, 90), # 10 / 32.2 C
        # cabbage looper

      dd_52: w.degree_days(52), # 11.1 C
        # colorado potato beetle
        # corn rootworm
        # tarnished plant bug

      dd_52_86: w.degree_days(52, 86), # 11.1 / 30 C
        # nothing yet
      
      dd_55_92: w.degree_days(55, 92) # 12.8 / 33.3 C
        # corn earworm
    )
  end

  def self.create_maps
    dd_models.each do |model|
      create_map(model)
    end
  end

  def self.create_map(
    model,
    start_date = latest_date.beginning_of_year,
    end_date = latest_date,
    units = "F",
    min_value = nil,
    max_value = nil,
    extent = "all"
  )

    raise ArgumentError.new("Invalid model!") unless model_names.include? model
    raise ArgumentError.new("Invalid units!") unless ["F", "C"].include? units

    dds = where(date: start_date..end_date, cumulative: false)

    unless dds.empty?
      totals = dds.group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .select(:latitude, :longitude, "sum(#{model}) as total")

      grid = (extent == "wi") ? LandGrid.wisconsin_grid : LandGrid.new
      totals.each do |point|
        lat, long = point.latitude, point.longitude
        next unless grid.inside?(lat, long)
        grid[lat, long] = (units == "F") ? point.total : UnitConverter.fdd_to_cdd(point.total)
      end

      # define map scale by rounding the interval up to divisible by 5
      tick = ((grid.max / 10.0) / 5.0).ceil * 5.0
      if min_value || max_value
        min_value ||= 0
        max_value ||= tick * 10
        title, file = dd_map_attr(model, start_date, end_date, units, min_value, max_value, extent)
      else
        title, file = dd_map_attr(model, start_date, end_date, units, min_value, max_value, extent)
        min_value = 0
        max_value = tick * 10
      end

      Rails.logger.info "#{name} :: Creating #{model} image for #{start_date} - #{end_date}"
      ImageCreator.create_image(grid, title, file, subdir: MAP_DIR, min_value:, max_value:)
    else
      Rails.logger.warn "PestForecast :: Failed to create image for #{model}: No data"
      "no_data.png"
    end
  end

  def self.dd_map_attr(model, start_date, end_date, units, min_value, max_value, extent)
    _, base, upper = model.tr("p", ".").split("_")
    if units == "C"
      base = "%g" % ("%.1f" % UnitConverter.f_to_c(base.to_f))
      upper = "%g" % ("%.1f" % UnitConverter.f_to_c(upper.to_f)) unless upper == "none"
    end
    model_name = "base #{base}°#{units}"
    model_name += ", upper #{upper}°#{units}" unless upper == "none"
    fmt2 = "%b %-d, %Y"
    fmt1 = (start_date.year != end_date.year) ? fmt2 : "%b %-d"
    title = "Degree day totals for #{model_name} from #{start_date.strftime(fmt1)} - #{end_date.strftime(fmt2)}"
    file = "#{units.downcase}dd-totals-for-#{model_name.tr(",°", "").tr(" ", "-").downcase}-from-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}"
    file += "-range-#{min_value.to_i}-#{max_value.to_i}" unless min_value.nil? && max_value.nil?
    file += "-wi" if extent == "wi"
    file += ".png"
    [title, file, base, upper]
  end
end
