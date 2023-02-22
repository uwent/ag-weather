class Insolation < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.default_col
    :insolation
  end

  def self.default_scale(units)
    units == "KWh" ? [0, 10] : [0, 30]
  end

  # per day per m^2
  def self.valid_units
    ["MJ", "KWh"].freeze
  end

  # value stored in MJ, converts if "KWh" requested
  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "KWh") ? UnitConverter.mj_to_kwh(value) : value
  end

  def self.image_subdir
    "insol"
  end

  def self.image_title(
    date: nil,
    start_date: nil,
    end_date: nil,
    units: valid_units[0],
    **args)
    
    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date

    if start_date.nil?
      "Daily insolation (#{units}/m2/day) for #{end_date.strftime("%-d %B %Y")}"
    else
      fmt = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      "Total insolation (#{units}/m2) for #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    end
  end
end
