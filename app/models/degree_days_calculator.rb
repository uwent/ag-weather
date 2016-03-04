class DegreeDaysCalculator 
  # All temperatures are in Fahrenheit.
  DEFAULT_BASE = 50
  DEFAULT_UPPER = 86
  INVERSE_PI = 1 / Math::PI

  def self.average_degree_days(min, max, base = DEFAULT_BASE)
    degree_hours = ((max + min) / 2.0) - base
    [degree_hours, 0.0].max
  end

  def self.modified_degree_days(min, max, base = DEFAULT_BASE,
                                upper = DEFAULT_UPPER)
    min = base if base > min
    max = base if base > max

    min = upper if upper < min
    max = upper if upper < max

    average_degree_hours(min, max, base)
  end

  def self.sine_degree_days(min, max, base = DEFAULT_BASE,
                            upper = DEFAULT_UPPER)
    average = (min + max) / 2.0
    alpha = (max - min) / 2.0
    o1 = Math.asin((base - average) / alpha)
    o2 = Math.asin((upper - average) / alpha)
    
    if (min >= upper) # both min and max are above the upper
      return upper - base 
    elsif (max > upper && min >= base) # max above upper, min between base/upper
      return INVERSE_PI * ((average - base) * (o2 + INVERSE_PI) +
                           (upper - base) * (Math::PI / 2 - o2) -
                           alpha * Math.cos(o2))
    elsif (max > upper && min < base) # max above upper, min below base
      return INVERSE_PI * ((average - base) * (o2 - o1) +
                           alpha * (Math.cos(o1) - Math.cos(o2)) +
                           (upper - base) * (Math::PI / 2 - o2))
    elsif (max <= upper && min >= base) # max and min both between base/upper 
      return average - base 
    elsif (max <= upper && min < base) # max between base/upper, min below base
      return INVERSE_PI * ((average - base) * (Math::PI / 2 - o1) +
                           alpha * Math.cos(o1))
    else # min and max both below base
      return 0
    end
  end
end
