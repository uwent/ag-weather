class DegreeDaysCalculator
  INVERSE_PI = 1 / Math::PI
  BASE_F = 50
  UPPER_F = 86
  BASE_C = 10
  UPPER_C = 30
  METHODS = ["sine", "average", "modified"]
  METHOD = "sine"

  # Min, max in Fahrenheit
  def self.calculate_f(min, max, base: BASE_F, upper: UPPER_F, method: METHOD)
    calculate(UnitConverter.f_to_c(min), UnitConverter.f_to_c(max), base:, upper:, method:)
  end

  # Min, max in Celcius
  def self.calculate(min, max, base: BASE_C, upper: UPPER_C, method: METHOD)
    case method.downcase
    when "average"
      average_degree_days(min, max, base)
    when "modified"
      modified_degree_days(min, max, base, upper)
    when "sine"
      sine_degree_days(min, max, base, upper)
    else
      raise ArgumentError, "method must be average, modified, or sine"
    end
  end

  def self.average_degree_days(min, max, base)
    degree_days = ((max + min) / 2.0) - base
    [degree_days, 0.0].max
  end

  def self.modified_degree_days(min, max, base, upper)
    min = base if base > min
    max = base if base > max

    min = upper if upper < min
    max = upper if upper < max

    average_degree_days(min, max, base)
  end

  # Reference: http://libcatalog.cimmyt.org/download/reprints/97465.pdf
  def self.sine_degree_days(min, max, base, upper)
    average = (min + max) / 2.0

    # both min and max greater than upper
    return upper - base if min >= upper

    # both min and max less than base
    return 0 if max <= base

    # both min and max between base and upper
    return average - base if max <= upper && min >= base

    alpha = (max - min) / 2.0

    # max is between base and upper, min is less than base
    if max <= upper && min < base
      base_radians = Math.asin((base - average) / alpha)
      a = average - base
      b = Math::PI / 2.0 - base_radians
      c = alpha * Math.cos(base_radians)
      INVERSE_PI * (a * b + c)
    # INVERSE_PI *
    #   ((average - base) * (Math::PI / 2 - time_of_base_threshold_in_radians) +
    #    alpha * Math.cos(time_of_base_threshold_in_radians))

    # max is greater than upper and min is between base and upper
    elsif max > upper && min >= base
      time_of_upper_threshold_in_radians = Math.asin((upper - average) / alpha)
      INVERSE_PI * (
        (average - base) * (time_of_upper_threshold_in_radians + Math::PI / 2) +
        (upper - base) * (Math::PI / 2 - time_of_upper_threshold_in_radians) -
        alpha * Math.cos(time_of_upper_threshold_in_radians)
      )

    # max is greater than upper and min is less than base
    elsif max > upper && min < base
      time_of_base_threshold_in_radians = Math.asin((base - average) / alpha)
      time_of_upper_threshold_in_radians = Math.asin((upper - average) / alpha)
      INVERSE_PI *
        ((average - base) *
         (time_of_upper_threshold_in_radians - time_of_base_threshold_in_radians) +
         alpha * (Math.cos(time_of_base_threshold_in_radians) -
                  Math.cos(time_of_upper_threshold_in_radians)) +
         (upper - base) * (Math::PI / 2 - time_of_upper_threshold_in_radians))
    end
  end
end
