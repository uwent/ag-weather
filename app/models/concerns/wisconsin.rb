module Wisconsin

  N_LAT = 47.1
  S_LAT = 42.5
  W_LONG = 92.9
  E_LONG = 86.8

  STEP = 0.1

  def self.inside?(lat, long)
    (lat >= S_LAT && lat <= N_LAT) && (long >= E_LONG && long <= W_LONG)
  end
end
