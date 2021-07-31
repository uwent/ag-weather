class RangeArray
  # include Enumerable

  EPSILON = 0.000001

  def initialize(min, max, step)
    raise TypeError, "minimum must be less than maximum" if (min >= max)
    raise TypeError, "step must be greater than 0" if (step <= 0)
    raise TypeError, "step must be less than the difference of max and min" if (step > max - min)
    @range = (min..max)
    @step = step
    @data = Array.new(number_of_points)
  end

  def each(&block)
    @data.compact.each(&block)
  end

  def number_of_points
    (1 + ((@range.max - @range.min) / @step) + EPSILON).floor
  end

  def point_at_index(idx)
    raise IndexError, "idx must be greater than zero" if idx < 0
    raise IndexError, "idx must be less than length" if idx >= number_of_points
    return (idx * @step + @range.min).round(6)
  end

  def closest_point(point)
    return @range.min if point < @range.min
    return point_at_index(number_of_points - 1) if point > @range.max
    return point_at_index(closest_index(point))
  end

  def includes_point?(point)
    (closest_point(point) - point).abs < EPSILON
  end

  def index_for_point(point)
    raise IndexError, "point [#{point}] not defined in RangeArray" unless (includes_point? point)
    closest_index(point)
  end

  def [](point)
    @data[index_for_point(point)]
  end

  def []=(point, value)
    @data[index_for_point(point)] = value
  end

  private 
    def closest_index(point)
      ((point - @range.min) / @step).round
    end
end
