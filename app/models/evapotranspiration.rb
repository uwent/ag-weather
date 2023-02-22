class Evapotranspiration < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.default_col
    :potential_et
  end

  def self.default_scale(units)
    units == "mm" ? [0, 8] : [0, 0.3]
  end

  def self.valid_units
    ["in", "mm"].freeze
  end

  # value stored in 'in', coverts if 'mm' requested
  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "mm") ? UnitConverter.in_to_mm(value) : value
  end

  def self.image_subdir
    "et"
  end

  def self.image_title(
    date: nil,
    start_date: nil,
    end_date: nil,
    units: valid_units[0],
    **args)
    
    end_date ||= date
    raise ArgumentError.new log_prefix + "Must provide either 'date' or 'end_date'" unless end_date

    if start_date.nil?
      "Potential evapotranspiration (#{units}/day) for #{end_date.strftime("%b %-d, %Y")}"
    else
      fmt1 = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      "Potential evapotranspiration (total #{units}) for #{start_date.strftime(fmt1)} - #{end_date.strftime("%b %-d, %Y")}"
    end
  end
end
