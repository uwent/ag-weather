class LandGrid
  EPSILON = 0.000001

  def self.number_of_points(min, max, step)
    1 + ((max - min) / step).round(6).floor
  end

  def initialize(min_lat, max_lat, min_long, max_long, step)
    raise TypeError, "minimum latitude must be less than maximum latitude" if
      (min_lat >= max_lat)
    raise TypeError, "minimum longitude must be less than maximum longitude" if
      (min_long >= max_long)
    raise TypeError, "step must be greater than 0" if (step <= 0)
    raise TypeError,
    "step must be less than latitude difference and longitude difference" if
      (step > max_lat - min_lat || step > max_long - min_long)

    @min_latitude = min_lat
    @max_latitude = max_lat
    @min_longitude = min_long
    @max_longitude = max_long
    @step = step
    @data = create_grid
  end

  def closest_latitude(lat)
    return @min_latitude if lat < @min_latitude
    return latitude_at_index(latitude_points - 1) if lat > @max_latitude
    closest_index = ((lat - @min_latitude) / @step).round
    return latitude_at_index(closest_index)
  end

  def closest_longitude(long)
    return @min_longitude if long < @min_longitude
    return longitude_at_index(longitude_points - 1) if long > @max_longitude
    closest_index = ((long - @min_longitude) / @step).round
    return longitude_at_index(closest_index)
  end

  def latitude_at_index(idx)
    raise IndexError, "idx must be greater than zero" if idx < 0
    raise IndexError, "idx must be less than length" if idx >= latitude_points
    return (idx * @step + @min_latitude).round(6)
  end

  def longitude_at_index(idx)
    raise IndexError, "idx must be greater than zero" if idx < 0
    raise IndexError, "idx must be less than length" if idx >= longitude_points
    return (idx * @step + @min_longitude).round(6)
  end

  def includes_latitude?(lat)
    (closest_latitude(lat) - lat).abs < EPSILON
  end

  def includes_longitude?(long)
    (closest_longitude(long) - long).abs < EPSILON
  end

  def [](lat, long)
    raise IndexError, "latitude [#{lat}] not defined in grid" unless includes_latitude?(lat)
    raise IndexError, "longitude [#{long}] not defined in grid" unless includes_longitude?(long)
    @data[index_for_latitude(lat)][index_for_longitude(long)]
  end

  def []=(lat, long, value)
    raise IndexError, "latitude [#{lat}] not defined in grid" unless includes_latitude?(lat)
    raise IndexError, "longitude [#{long}] not defined in grid" unless includes_longitude?(long)
    @data[index_for_latitude(lat)][index_for_longitude(long)] = value
  end

  private
    def create_grid
      Array.new(latitude_points) { Array.new(longitude_points) }
    end

    def latitude_points
      self.class.number_of_points(@min_latitude, @max_latitude, @step)
    end

    def longitude_points
      self.class.number_of_points(@min_longitude, @max_longitude, @step)
    end

    def index_for_latitude(lat)
      ((lat - @min_latitude) / @step).round
    end

    def index_for_longitude(lat)
      ((lat - @min_latitude) / @step).round
    end
end
