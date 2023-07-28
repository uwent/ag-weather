class Weather < ApplicationRecord
  attribute :latitude, :float
  attribute :longitude, :float

  extend GridMethods
  extend ImageMethods

  def self.default_col
    :avg_temp
  end

  def self.default_stat
    :avg
  end

  def self.image_subdir
    "weather"
  end

  def self.temperature_defaults
    {
      units: "C", # stored value
      valid_units: ["F", "C"], # first is default display unit
      gnuplot_scale: {
        "F" => [0, 100],
        "C" => [-20, 40]
      }
    }
  end

  def self.col_attr
    {
      min_temp: {name: "Min air temp"}.merge(temperature_defaults),
      max_temp: {name: "Max air temp"}.merge(temperature_defaults),
      avg_temp: {name: "Avg air temp"}.merge(temperature_defaults),
      min_rh: {name: "Min relative humidity", units: "%"},
      max_rh: {name: "Max relative humidity", units: "%"},
      avg_rh: {name: "Avg relative humidity", units: "%"},
      vapor_pressure: {name: "Vapor pressure", units: "kPa"},
      dew_point: {name: "Dew point"}.merge(temperature_defaults),
      hours_rh_over_90: {name: "Hours high RH (>90%)", units: "hours"},
      avg_temp_rh_over_90: {name: "Avg air temp (RH >90%)"}.merge(temperature_defaults),
      frost: {name: "Frost days"}, # number of days < 0 C
      freezing: {name: "Freezing days"} # number of days < 2 C
    }.freeze
  end

  def self.col_name(col)
    check_col(col)
    col_attr[col.to_sym][:name]
  end

  def self.default_units(col)
    check_col(col)
    col_attr[col.to_sym][:units]
  end

  def self.valid_units(col)
    check_col(col)
    col_attr[col.to_sym][:valid_units] || [default_units(col)]
  end

  def self.default_scale(col:, units: nil)
    check_col(col)
    scales = col_attr[col.to_sym][:gnuplot_scale]
    return unless scales
    scales.is_a?(Hash) ? scales[units] : scales
  end

  # only converts temperature otherwise returns value unchanged
  def self.convert(col:, value:, units: nil)
    check_col(col)
    return value unless units
    valid_units = valid_units(col)
    if valid_units
      raise ArgumentError.new "Unit has invalid value: #{units.inspect}. Must be one of #{valid_units.join(", ")}" unless valid_units.include? units
      if ["C", "F"].include? units
        value = (units == "F") ? UnitConverter.c_to_f(value) : value
      end
    end
    value
  end

  def self.image_name_prefix(col:, stat: nil, **args)
    str = col_name(col) || "weather"
    str = str.downcase.tr(" ", "-")
    str = "#{stat}-#{str}" if stat && stat.to_s != str.split("-")[0] # avoid repeating same word
    str
  end

  def self.image_title(col:, date: nil, start_date: nil, end_date: nil, units: nil, stat: nil)
    end_date ||= date
    raise ArgumentError.new(log_prefix + "Must provide either 'date' or 'end_date'") unless end_date
    title = col_name(col)
    title = "#{stat.to_s.humanize} #{title.downcase}" if stat && stat.to_s.humanize != title.split(" ")[0]
    title += " (#{units})" if units
    datestring = image_title_date(start_date:, end_date:)
    "#{title} for #{datestring}"
  end

  def self.new_from_observations(observations)
    temps = observations.map(&:temperature).compact
    dew_points = observations.map(&:dew_point).compact
    humidities = observations.map(&:relative_humidity).compact
    dew_point = true_avg(dew_points)
    vapor_pressure = UnitConverter.temp_to_vp(dew_point)

    Weather.new(
      min_temp: temps.min,
      max_temp: temps.max,
      avg_temp: true_avg(temps),
      dew_point:,
      vapor_pressure:,
      min_rh: humidities.min,
      max_rh: humidities.max,
      avg_rh: true_avg(humidities),
      hours_rh_over_90: count_rh_over(humidities, 90.0),
      avg_temp_rh_over_90: avg_temp_rh_over(observations, 90.0)
    )
  end

  def self.count_rh_over(humidities, rh_cutoff)
    humidities.count { |x| x >= rh_cutoff }
  end

  def self.avg_temp_rh_over(observations, rh_cutoff)
    rh_obs = observations.select do |obs|
       obs.relative_humidity && obs.temperature &&
       obs.relative_humidity >= rh_cutoff
    end
    (rh_obs.map(&:temperature).sum / rh_obs.size) if rh_obs.size >= 1
  end

  def self.simple_avg(array)
    array.compact!
    return nil if array.empty?
    (array.max + array.min) / 2.0
  end

  def self.true_avg(array)
    array.compact!
    return nil if array.empty?
    array.sum.to_f / array.size
  end

  # min_temp/max_temp stored in C, must be converted if F
  def degree_days(base:, upper: 150, method: "sine", in_f: true)
    if in_f
      min = UnitConverter.c_to_f(min_temp)
      max = UnitConverter.c_to_f(max_temp)
      DegreeDaysCalculator.calculate(min:, max:, base:, upper:, method:)
    else
      DegreeDaysCalculator.calculate(min: min_temp, max: max_temp, base:, upper:, method:)
    end
  end
end
