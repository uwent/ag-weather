class LandExtent

  # Small box around Madison for test suites.
  N_LAT = 43.5
  S_LAT = 42.5
  W_LONG = 90.0
  E_LONG = 89.0

  STEP = 0.1

  def self.latitudes
    (S_LAT..N_LAT)
  end

  def self.longitudes
    (E_LONG..W_LONG)
  end

  def self.step
    STEP
  end

  def self.inside?(lat, long)
    (self.latitudes === lat) && (self.longitudes === long)
  end

  def self.each_point(step = self.step)
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |long|
        yield(lat, long)
      end
    end
  end

end
