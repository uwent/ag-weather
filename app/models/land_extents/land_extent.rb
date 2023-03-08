class LandExtent
  STEP = 0.1

  def self.lat_range
    38.0..50.0
  end

  def self.long_range
    -98.0..-82.0
  end

  def self.step
    STEP
  end

  def self.latitudes
    lat_range.step(step)
  end

  def self.longitudes
    long_range.step(step)
  end

  def self.min_lat
    lat_range.min
  end

  def self.max_lat
    lat_range.max
  end

  def self.min_long
    long_range.min
  end

  def self.max_long
    long_range.max
  end

  def self.num_latitudes
    latitudes.count
  end

  def self.num_longitudes
    longitudes.count
  end

  def self.num_points
    num_latitudes * num_longitudes
  end

  def self.inside?(lat, long)
    (lat_range === lat) && (long_range === long)
  end

  def self.random_point
    lat = rand(lat_range).round(1)
    long = rand(long_range).round(1)
    [lat, long]
  end

  def self.each_point
    latitudes.each do |lat|
      longitudes.each do |long|
        yield(lat, long)
      end
    end
  end

  def self.create_grid(default_value = nil)
    hash = {}
    each_point do |lat, long|
      hash[[lat, long]] = default_value
    end
    hash
  end
end
