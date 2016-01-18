module WiMn

  N_LAT = 50
  S_LAT = 42
  W_LONG = 98
  E_LONG = 86

  def inside_wi_mn_box?(lat, long)
    (lat > S_LAT && lat < N_LAT) && (long > E_LONG && long < W_LONG)
  end
end
