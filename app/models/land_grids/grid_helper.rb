class GridHelper

  # N_LAT = 1
  # S_LAT = 0
  # W_LON = 0
  # E_LON = 1

  STEP = 0.1

  def self.inside?(lat, lon)
    (lat >= self::S_LAT && lat <= self::N_LAT) &&
    (lon >= self::W_LON && lon <= self::E_LON)
  end

  def self.latitudes
    (self::S_LAT..self::N_LAT)
  end

  def self.longitudes
    (self::W_LON..self::E_LON)
  end

  def self.each_point(step = self::STEP)
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |lon|
        yield(lat, lon)
      end
    end
  end

end
