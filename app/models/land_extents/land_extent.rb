class LandExtent

  # Upper midwest area. Degrees west longitude.
  N_LAT = 50
  S_LAT = 38
  W_LONG = 100
  E_LONG = 80

  STEP = 0.1

  def self.inside?(lat, long)
    (lat >= self::S_LAT && lat <= self::N_LAT) &&
    (long >= self::E_LONG && long <= self::W_LONG)
  end

  def self.latitudes
    (self::S_LAT..self::N_LAT)
  end

  def self.longitudes
    (self::E_LONG..self::W_LONG)
  end

  def self.each_point(step = self::STEP)
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |long|
        yield(lat, long)
      end
    end
  end

end
