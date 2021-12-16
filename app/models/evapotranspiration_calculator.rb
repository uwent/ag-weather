class EvapotranspirationCalculator
  # This is an implementation of evapotranspiration based on the formula in
  # the paper:  http://wisp.cals.wisc.edu/diakEtal1998.pdf.

  SOLAR_CONSTANT = 1367.0
  WATTS_TO_MJ_PER_DAY = 0.0864
  STEFAN_WATTS = 0.0000000567
  STEFAN_MJ_PER_DAY = WATTS_TO_MJ_PER_DAY * STEFAN_WATTS
  SFCEMISS = 0.96
  ALBEDO = 0.25

  def self.degrees_to_rads(degrees)
    degrees * Math::PI / 180.0
  end

  def self.declin(day_of_year)
    0.41 * Math.cos(2 * Math::PI * (day_of_year - 172.0) / 365.0)
  end

  def self.sunrise_angle(day_of_year, lat)
    Math.acos(-1 * Math.tan(declin(day_of_year)) *
    Math.tan(degrees_to_rads(lat)))
  end

  def self.sunrise_hour(day_of_year, lat)
    12 - (12 / Math::PI) * sunrise_angle(day_of_year, lat)
  end

  def self.day_hours(day_of_year, lat)
    24 - 2 * sunrise_hour(day_of_year, lat)
  end

  # Only used by clr_ratio.
  def self.av_eir(day_of_year)
    SOLAR_CONSTANT * (1 + 0.035 * Math.cos(2 * Math::PI * day_of_year / 365.0))
  end

  # Only used by clr_ratio.
  def self.to_eir(day_of_year, lat)
    (0.0864 / Math::PI) *
      av_eir(day_of_year) * (
        sunrise_angle(day_of_year, lat) *
        Math.sin(declin(day_of_year)) *
        Math.sin(degrees_to_rads(lat)) +
        Math.cos(declin(day_of_year)) *
        Math.cos(degrees_to_rads(lat)) *
        Math.sin(sunrise_angle(day_of_year, lat))
      )
  end

  # Only used by clr_ratio.
  def self.to_clr(day_of_year, lat)
    to_eir(day_of_year, lat) * (-0.7 + 0.86 * day_hours(day_of_year, lat)) / day_hours(day_of_year, lat)
  end

  # Estimation of upwelling thermal radition from the land given the
  # surface air temperature using the surface emissivity for vegetated
  # surfaces and the Stefan-Boltzmann constant.
  def self.lwu(avg_temp)
    SFCEMISS * STEFAN_MJ_PER_DAY * (273.15 + avg_temp)**4
  end

  # This seems to represent S, the slope of the saturation vapor pressure curve
  # with respect to temperature of the air and gamma, the psychrometric constant
  # In the paper this is (S/(S + gamma)).
  def self.sfactor(avg_temp)
    0.398 + (0.0171 * avg_temp) - (0.000142 * avg_temp * avg_temp)
  end

  # A clear-sky emissivity (dimensionless) calculated using the method of
  # Idso (1981)
  def self.sky_emiss(avg_v_press, avg_temp)
    if avg_v_press > 0.5
      0.7 + 5.95e-4 * avg_v_press * Math.exp(1500 / (273 + avg_temp))
    else
      (1 - 0.261 * Math.exp(-0.000777 * avg_temp * avg_temp))
    end
  end

  # This calculates (1 minus clear-sky emissivity) factor of L_nc in paper.
  def self.angstrom(avg_v_press, avg_temp)
    1.0 - sky_emiss(avg_v_press, avg_temp) / SFCEMISS
  end

  # The ratio of the measured insolation divided by the theoretical value
  # calculated for clear-air conditions.
  def self.clr_ratio(d_to_sol, day_of_year, lat)
    tc = to_clr(day_of_year, lat)
    # Never return higher than 1
    [d_to_sol / tc, 1.0].min
  end

  # This is the net thermal infrared flux term (Ln) of the total net
  # radiation consisting of the two directional terms upwelling and downwelling.
  def self.lwnet(avg_v_press, avg_temp, d_to_sol, day_of_year, lat)
    angstrom(avg_v_press, avg_temp) *
      lwu(avg_temp) *
      clr_ratio(d_to_sol, day_of_year, lat)
  end

  # temperatures are in Celsius
  # avg_v_pressure is in kPa (kilopascals)
  # d_to_sol is insolation reading in MJ/day (Megajoules/day)
  # lat is latitude in fractional degrees
  def self.et(avg_temp, avg_v_press, d_to_sol, day_of_year, lat)
    # calculates L_n in the paper (represents L_u - L_d)
    lwnet = lwnet(avg_v_press, avg_temp, d_to_sol, day_of_year, lat)
    # calculates R_n in paper
    net_radiation = (1.0 - ALBEDO) * d_to_sol - lwnet
    # Evapotranspiration. Unsure why 1.28, not 1.26 as written in the paper
    pot_et = 1.28 * sfactor(avg_temp) * net_radiation
    # Assume the 62.3 is a conversion factor, but unable to determine.
    [pot_et / 62.3, 0].max
    # In winter, at high latitudes, et was coming out as a small negative number
  end
end
