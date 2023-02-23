class DegreeDaysCalculator
  INVERSE_PI = 1 / Math::PI
  BASE_F = 50.0
  UPPER_F = 86.0
  BASE_C = 10.0
  UPPER_C = 30.0
  METHODS = ["sine", "average", "modified"]
  METHOD = "sine"

  def self.calculate_f(min:, max:, base: BASE_F, upper: UPPER_F, method: METHOD)
    calculate(min:, max:, base:, upper:, method:)
  end

  # Temperatures in C by default
  def self.calculate(min:, max:, base: BASE_C, upper: UPPER_C, method: METHOD)
    min = min.to_f
    max = max.to_f
    base = base.to_f
    upper = (upper || 150.0).to_f
    method ||= METHOD
    dd = case method.downcase
    when "average"
      average_degree_days(min, max, base)
    when "modified" # uses upper threshold cutoff
      modified_degree_days(min, max, base, upper)
    when "sine"
      sine_degree_days(min, max, base, upper)
    else
      raise ArgumentError, "method must be average, modified, or sine"
    end
    [dd, 0.0].max if dd
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
    return 0.0 if max <= base

    # both min and max between base and upper
    return average - base if max <= upper && min >= base

    alpha = (max - min) / 2.0

    # max is between base and upper, min is less than base
    if max <= upper && min < base
      btr = Math.asin((base - average) / alpha) # time of base threshold in radians
      a = average - base
      b = Math::PI / 2.0 - btr
      c = alpha * Math.cos(btr)
      return (a * b + c) / Math::PI
    end

    # max is greater than upper and min is between base and upper
    if max > upper && min >= base
      btr = Math.asin((upper - average) / alpha) # time of base threshold in radians
      a = average - base
      b = btr + Math::PI / 2
      c = upper - base
      d = (Math::PI / 2 - btr)
      e = alpha * Math.cos(btr)
      return (a * b + c * d - e) / Math::PI
    end

    # max is greater than upper and min is less than base
    if max > upper && min < base
      btr = Math.asin((base - average) / alpha) # time of base threshold in radians
      utr = Math.asin((upper - average) / alpha) # time of upper threshold in radians
      a = average - base
      b = utr - btr
      c = alpha * (Math.cos(btr) - Math.cos(utr))
      d = upper - base
      e = Math::PI / 2 - utr
      return (a * b + c + d * e) / Math::PI
    end
  end
end
