class LandExtent
  STEP = 0.1

  def self.latitudes
    38.0..50.0
  end

  def self.longitudes
    -98.0..-82.0
  end

  def self.step
    STEP
  end

  def self.min_lat
    latitudes.min.to_d.round(1)
  end

  def self.max_lat
    latitudes.max.to_d.round(1)
  end

  def self.min_long
    longitudes.min.to_d.round(1)
  end

  def self.max_long
    longitudes.max.to_d.round(1)
  end

  def self.random_point
    lat = rand(latitudes).round(1)
    long = rand(longitudes).round(1)
    [lat, long]
  end

  def self.inside?(lat, long)
    (latitudes === lat) && (longitudes === long)
  end

  def self.num_points
    latitudes.step(step).count * longitudes.step(step).count
  end

  def self.each_point(step = STEP)
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |long|
        yield(lat, long)
      end
    end
  end
end
