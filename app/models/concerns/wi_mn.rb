module WiMn

  N_LAT = 50
  S_LAT = 42
  W_LONG = 98
  E_LONG = 86

  def self.inside_wi_mn_box?(lat, long)
    (lat > S_LAT && lat < N_LAT) && (long > E_LONG && long < W_LONG)
  end

  def self.latitudes
    (S_LAT...N_LAT)
  end

  def self.longitudes
    (E_LONG...W_LONG)
  end

  def self.each_point
    latitudes.step(0.1).each do |latitude|
      longitudes.step(0.1).each do |longitude|
        yield(latitude, longitude)
      end
    end
  end

end
