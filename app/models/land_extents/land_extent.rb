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

  def self.num_points
    latitudes.count * longitudes.count
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
end
