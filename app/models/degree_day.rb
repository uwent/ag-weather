class DegreeDay < ApplicationRecord
  extend GridMethods
  extend ImageMethods

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
      # aphid pvy model
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

  def self.default_col
    :dd_50
  end

  def self.valid_units
    ["F", "C"].freeze
  end

  def self.image_subdir
    "degree_days"
  end

  # value stored in FDD, converts if "CDD" requested
  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "C") ? UnitConverter.fdd_to_cdd(value) : value
  end

  # must be sent :col and :units
  def self.image_name_prefix(col:, units:, **args)
    base, upper = dd_to_base_upper(col, units)
    str = "degree-days-base-#{base}"
    str += "-upper-#{upper}" if upper
    str
  end

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

  # model name format like "dd_42p8_86" in Fahrenheit
  def self.dd_to_base_upper(model, units)
    _, base, upper = model.to_s.tr("p", ".").split("_")
    if units == "C"
      base = "%g" % ("%.1f" % UnitConverter.f_to_c(base.to_f))
      upper = "%g" % ("%.1f" % UnitConverter.f_to_c(upper.to_f)) if upper
    end
    [base, upper]
  end

  def self.find_model(base, upper = nil, units = "F")
    raise ArgumentError.new("Must provide base temperature") if base.nil?
    if units == "C"
      base = UnitConverter.c_to_f(base)
      upper = UnitConverter.c_to_f(upper)
    end
    model = "dd_" + sprintf("%.4g", base)
    model += sprintf("_%.4g", upper) if upper
    model.gsub(/\./, "p")
  end

  def self.image_title(
    col:,
    date: nil,
    start_date: nil,
    end_date: nil,
    units: valid_units[0],
    **args)

    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date

    base, upper = dd_to_base_upper(col, units)
    dd_name = "base #{base}°#{units}"
    dd_name += ", upper #{upper}°#{units}" if upper
    if start_date
      fmt = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      "Degree day totals #{dd_name} from #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    else
      "Degree day totals #{dd_name} on #{end_date.strftime("%b %-d, %Y")}"
    end
  end
end
