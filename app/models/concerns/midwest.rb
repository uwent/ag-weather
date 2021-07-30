module Midwest

  N_LAT = 50
  S_LAT = 40
  W_LONG = 98
  E_LONG = 80

  STEP = 0.1

  def self.inside?(lat, long)
    (lat >= S_LAT && lat <= N_LAT) &&
    (long >= E_LONG && long <= W_LONG)
  end

  def self.latitudes
    (S_LAT..N_LAT)
  end

  def self.longitudes
    (E_LONG..W_LONG)
  end

  def self.each_point(step = STEP)
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |long|
        yield(lat, long)
      end
    end
  end

end
