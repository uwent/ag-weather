class DegreeDay < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.new_from_weather(w)
    new(
      date: w.date,
      latitude: w.latitude,
      longitude: w.longitude,

      dd_32: w.degree_days(base: 32), # 0 C
      # nothing yet

      dd_38_75: w.degree_days(base: 38, upper: 75), # 3.3 C / 23.9 C
      # nothing yet

      dd_39p2_86: w.degree_days(base: 39.2, upper: 86), # 4 / 30 C
      # aphid pvy model
      # onion maggot
      # seedcorn maggot

      dd_41: w.degree_days(base: 41), # 5 C
      # flea beetle
      # oak wilt vectors

      dd_41_86: w.degree_days(base: 41, upper: 86), # 5 / 30 C
      # stalk borer

      dd_42p8_86: w.degree_days(base: 42.8, upper: 86), # 6 / 30 C
      # cabbage maggot

      dd_45: w.degree_days(base: 45), # 7.2 C
      # western flower thrips

      dd_45_80p1: w.degree_days(base: 45, upper: 80.1), # 7.2 / 26.7
      # variegated cutworm

      dd_45_86: w.degree_days(base: 45, upper: 86), # 7.2 / 30 C
      # spotted wing drosophila

      dd_48: w.degree_days(base: 48), # 9 C
      # alfalfa weevil

      dd_50: w.degree_days(base: 50), # 10 C
      # BMSB (dubious)
      # flea beetle (crucifer)
      # imported cabbageworm
      # japanese beetle
      # mint root borer
      # squash vine borer
      # western bean cutworm

      dd_50_86: w.degree_days(base: 50, upper: 86), # 10 / 30 C
      # asparagus beetle (common)
      # black cutworm
      # european corn borer

      dd_50_87p8: w.degree_days(base: 50, upper: 87.8), # 10 / 31 C
      # no insect model

      dd_50_90: w.degree_days(base: 50, upper: 90), # 10 / 32.2 C
      # cabbage looper

      dd_52: w.degree_days(base: 52), # 11.1 C
      # colorado potato beetle
      # corn rootworm
      # tarnished plant bug

      dd_52_86: w.degree_days(base: 52, upper: 86), # 11.1 / 30 C
      # nothing yet

      dd_55_92: w.degree_days(base: 55, upper: 92) # 12.8 / 33.3 C
      # corn earworm
    )
  end

  def self.default_col
    :dd_50
  end

  def self.default_stat
    :sum
  end

  def self.valid_units
    ["F", "C"].freeze
  end

  # value stored in FDD, converts if "CDD" requested
  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "C") ? UnitConverter.fdd_to_cdd(value) : value
  end

  # must be sent :col and :units
  def self.image_name_prefix(col:, units:, stat:, **args)
    base, upper = parse_model(col, units)
    str = ""
    str += "#{stat}-" if stat && stat != default_stat
    str += "degree-days-base-#{base}"
    str += "-upper-#{upper}" if upper
    str
  end

  def self.model_names
    data_cols.map(&:to_s)
  end

  # model name format like "dd_42p8_86" in Fahrenheit
  def self.parse_model(model, units)
    _, base, upper = model.to_s.tr("p", ".").split("_")
    if units.upcase == "C"
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
    model = "dd_" + sprintf("%.4g", base.round(1))
    model += sprintf("_%.4g", upper.round(1)) if upper
    model.tr(".", "p")
  end

  def self.image_subdir
    "degree_days"
  end

  def self.image_title(col:, date: nil, start_date: nil, end_date: nil, units: valid_units[0], **args)
    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date
    check_units(units)
    base, upper = parse_model(col, units)
    dd_name = "base #{base}°#{units}"
    dd_name += ", upper #{upper}°#{units}" if upper
    datestring = image_title_date(start_date:, end_date:)
    "Degree day totals #{dd_name} for #{datestring}"
  end
end
