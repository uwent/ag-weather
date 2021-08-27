class LandExtent

  STEP = 0.1

  def self.latitudes
    BigDecimal("38.0")..BigDecimal("50.0")
  end

  def self.longitudes
    BigDecimal("-98.0")..BigDecimal("-82.0")
  end

  def self.step
    STEP
  end

  def self.min_lat
    latitudes.min
  end

  def self.max_lat
    latitudes.max
  end

  def self.min_long
    longitudes.min
  end

  def self.max_long
    longitudes.max
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
