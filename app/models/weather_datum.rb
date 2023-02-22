class WeatherDatum < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.col_attr
    {
      min_temp: {
        name: "Min air temp",
        units: "C",
        valid_units: ["C", "F"]
      },
      max_temp: {
        name: "Max air temp",
        units: "C",
        valid_units: ["C", "F"]
      },
      avg_temp: {
        name: "Avg air temp",
        units: "C",
        valid_units: ["C", "F"]
      },
      min_rh: {
        name: "Min relative humidity",
        units: "%"
      },
      max_rh: {
        name: "Max relative humidity",
        units: "%"
      },
      avg_rh: {
        name: "Avg relative humidity",
        units: "%"
      },
      vapor_pressure: {
        name: "Vapor pressure",
        units: "kPa"
      },
      dew_point: {
        name: "Dew point",
        units: "C",
        valid_units: ["C", "F"]
      },
      frost: {
        name: "Frost days"
      }, # number of days < 0 C
      freezing: {
        name: "Freezing days"
      } # number of days < 2 C
    }
  end

  def self.default_col
    :avg_temp
  end

  def self.default_stat
    :avg
  end

  def self.col_name(col)
    col_attr[col.to_sym][:name]
  end

  def self.valid_units(col)
    col_attr[col.to_sym][:valid_units]
  end

  def self.default_units(col)
    col_attr[col.to_sym][:units]
  end

  def self.convert(col:, value:, units:)
    valid_units = valid_units(col)
    if valid_units
      raise ArgumentError.new(log_prefix(1) + "Unit has invalid value: #{units.inspect}. Must be one of #{valid_units.join(", ")}") unless valid_units.include? units
      if ["C", "F"].include? units
        value = (units == "F") ? UnitConverter.c_to_f(value) : value
      end
    end
    value
  end

  def self.image_subdir
    "weather"
  end

  def self.image_name_prefix(col:, stat: nil, **args)
    str = col_name(col) || "weather"
    str = str.downcase.tr(" ", "-")
    str = "#{stat}-#{str}" if stat && stat.to_s != str.split("-")[0] # avoid repeating same word
    str
  end

  def self.image_title(
    col:,
    date: nil,
    start_date: nil,
    end_date: nil,
    units: nil,
    stat: nil
  )

    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date

    title = col_name(col)
    title = "#{stat.to_s.humanize} #{title.downcase}" if stat && stat.to_s.humanize != title.split(" ")[0]
    title += " (#{units}) " if units
    if start_date
      fmt = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      title += "from #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    else
      title += "on #{end_date.strftime("%b %-d, %Y")}"
    end
    title
  end

  # fahrenheit min/max. base/upper must be F
  def degree_days(base, upper = 150, method = DegreeDaysCalculator::METHOD, in_f = true)
    min = in_f ? UnitConverter.c_to_f(min_temp) : min_temp
    max = in_f ? UnitConverter.c_to_f(max_temp) : max_temp
    dd = DegreeDaysCalculator.calculate(min, max, base:, upper:, method:)
    [0, dd].max unless dd.nil?
  end
end
