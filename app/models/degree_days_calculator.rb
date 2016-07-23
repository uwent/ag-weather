class DegreeDaysCalculator
  DEFAULT_BASE = 50
  DEFAULT_UPPER = 86
  INVERSE_PI = 1 / Math::PI

  def self.to_fahrenheit(celcius)
    celcius.to_f * 9.0/5.0 + 32.0
  end

  def self.to_celcius(fahrenheit)
    (fahrenheit.to_f - 32.0).to_f * 5.0/9.0
  end

  # Min, max in Fahrenheit
  def self.calculate(method, min, max,
                     base = DEFAULT_BASE, upper = DEFAULT_UPPER)
    if method == "average"
      return average_degree_days(min, max, base)
    elsif method == "modified"
      return modified_degree_days(min, max, base)
    elsif method == "sine"
      return sine_degree_days(min, max, base, upper)
    else
      raise ArgumentError, "method must be average, modified, or sine"
    end
  end

  # Min, max in Fahrenheit.
  def self.average_degree_days(min, max, base = DEFAULT_BASE)
    degree_days = ((max + min) / 2.0) - base
    [degree_days, 0.0].max
  end

  # Min, max in Fahrenheit.
  def self.modified_degree_days(min, max, base = DEFAULT_BASE,
                                upper = DEFAULT_UPPER)
    min = base if base > min
    max = base if base > max

    min = upper if upper < min
    max = upper if upper < max

    average_degree_days(min, max, base)
  end

  # Reference: http://libcatalog.cimmyt.org/download/reprints/97465.pdf
  # Min, max in Fahrenheit.
  def self.sine_degree_days(min, max, base = DEFAULT_BASE,
                            upper = DEFAULT_UPPER)

    average = (min + max) / 2.0
    return upper - base if (min >= upper) # both min and max greater than upper
    return 0 if (max <= base) # both min and max less than base
    # both min and max between base and upper
    return average - base if (max <= upper && min >= base)

    alpha = (max - min) / 2.0
    # max is between base and upper, min is less than base
    if (max <= upper && min < base)
      time_of_base_threshold_in_radians = Math.asin((base - average) / alpha)
      return INVERSE_PI *
        ((average - base) *  (Math::PI / 2 - time_of_base_threshold_in_radians) +
         alpha * Math.cos(time_of_base_threshold_in_radians))
    # max is greater than upper and min is between base and upper
    elsif (max > upper && min >= base)
      time_of_upper_threshold_in_radians = Math.asin((upper - average) / alpha)
      return INVERSE_PI * ((average - base) *
                           (time_of_upper_threshold_in_radians + Math::PI/2) +
                           (upper - base) *
                           (Math::PI / 2 - time_of_upper_threshold_in_radians) -
                           alpha * Math.cos(time_of_upper_threshold_in_radians))
    # max is greater than upper and min is less than base
    elsif (max > upper && min < base)
      time_of_base_threshold_in_radians = Math.asin((base - average) / alpha)
      time_of_upper_threshold_in_radians = Math.asin((upper - average) / alpha)
      return INVERSE_PI *
        ((average - base) *
         (time_of_upper_threshold_in_radians - time_of_base_threshold_in_radians) +
         alpha * (Math.cos(time_of_base_threshold_in_radians) -
                  Math.cos(time_of_upper_threshold_in_radians)) +
         (upper - base) * (Math::PI / 2 - time_of_upper_threshold_in_radians))
    end
  end
end
