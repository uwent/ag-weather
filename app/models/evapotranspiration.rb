class Evapotranspiration < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.default_col
    :potential_et
  end

  def self.valid_units
    ["in", "mm"].freeze
  end

  # value stored in 'in', coverts if 'mm' requested
  # raises error on invalid units
  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "mm") ? UnitConverter.in_to_mm(value) : value
  end

  # subdirectory for et images
  def self.image_subdir
    "et"
  end

  # depending on units, set default scale for gnuplot images
  def self.default_scale(units:, **args)
    check_units(units)
    (units == "mm") ? [0, 8] : [0, 0.3]
  end

  # creates a title for the gnuplot image
  def self.image_title(date: nil, start_date: nil, end_date: nil, units: valid_units[0], **args)
    end_date ||= date
    raise ArgumentError.new "Must provide either 'date' or 'end_date'" unless end_date
    check_units(units)
    datestring = image_title_date(start_date:, end_date:)
    "Potential evapotranspiration (#{units}) for #{datestring}"
  end
end
