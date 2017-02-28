module Wisconsin

  N_LAT = 47.1
  S_LAT = 42
  W_LONG = 93.1
  E_LONG = 86.8

  STEP = 0.1

  def self.inside?(lat, long)
    (lat >= S_LAT && lat <= N_LAT) && (long >= E_LONG && long <= W_LONG)
  end

  def self.latitudes
    (S_LAT..N_LAT)
  end

  def self.longitudes
    (E_LONG..W_LONG)
  end

  def self.each_point(step=STEP)
    latitudes.step(step).each do |latitude|
      longitudes.step(step).each do |longitude|
        yield(latitude, longitude)
      end
    end
  end
end
