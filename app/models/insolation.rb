class Insolation < ApplicationRecord
  attribute :latitude, :float
  attribute :longitude, :float

  extend GridMethods
  extend ImageMethods

  def self.default_col
    :insolation
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

  def self.default_scale(units:, **args)
    check_units(units)
    (units == "KWh") ? [0, 8] : [0, 30]
  end

  def self.image_title(date: nil, start_date: nil, end_date: nil, units: valid_units[0], stat: nil, **args)
    end_date ||= date
    raise ArgumentError.new "Must provide either 'date' or 'end_date'" unless end_date
    check_units(units)

    title = "Daily solar insolation"
    stat = (stat == :sum) ? "total" : stat
    title = "#{stat.to_s.humanize} #{title.downcase}" if stat && stat.to_s.humanize != title.split(" ")[0]
    title += " (#{units}/m2)" if units
    datestring = image_title_date(start_date:, end_date:)
    "#{title} for #{datestring}"
  end
end
