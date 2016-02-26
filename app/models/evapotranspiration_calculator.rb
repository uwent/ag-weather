class EvapotranspirationCalculator
  SOLCON    = 1367.0
  STEFAN    = (0.0864 * 0.0000000567)
  SFCEMISS  = 0.96
  ALBEDO    = 0.25

  def self.degrees_to_rads(degrees)
    degrees * Math::PI / 180.0
  end

  def self.declin(day_of_year)
    0.41 *  Math::cos(2 * Math::PI * (day_of_year - 172.0) / 365.0)
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

  def self.av_eir(day_of_year)
    SOLCON * (1 + 0.035 * Math.cos(2 * Math::PI * day_of_year / 365.0))
  end
  
  def self.to_eir(day_of_year, lat)
      (0.0864 / Math::PI) * av_eir(day_of_year) * 
      (sunrise_angle(day_of_year, lat) *
       Math.sin(declin(day_of_year)) *
       Math.sin(degrees_to_rads(lat)) +
       Math.cos(declin(day_of_year)) *
       Math.cos(degrees_to_rads(lat)) *
       Math.sin(sunrise_angle(day_of_year, lat)))
  end
    
  def self.to_clr(day_of_year, lat)
    to_eir(day_of_year, lat) * 
      (-0.7 + 0.86 * day_hours(day_of_year, lat)) / 
      day_hours(day_of_year, lat)
  end

  def self.lwu(avg_temp)
    SFCEMISS * STEFAN * (273.15 + avg_temp) ** 4
  end
    
  def self.sfactor(avg_temp)
    0.398 + 0.0171 * avg_temp - 0.000142 * avg_temp * avg_temp
  end

  def self.sky_emiss(avg_v_press, avg_temp)
    if (avg_v_press > 0.5)
      0.7 + (5.95e-4) * avg_v_press * Math.exp(1500/(273 + avg_temp))
    else
      (1 - 0.261 * Math.exp(-0.000777 * avg_temp * avg_temp))
    end
  end
  
  def self.angstrom(avg_v_press, avg_temp)
    1.0 - sky_emiss(avg_v_press, avg_temp) / SFCEMISS
  end

  def self.clr_ratio(d_to_sol, day_of_year, lat)
    tc = to_clr(day_of_year, lat)
    # Never return higher than 1
    [d_to_sol / tc, 1.0].min
  end

  def self.lwnet(avg_v_press, avg_temp, d_to_sol, 
                 day_of_year, lat)
    angstrom(avg_v_press, avg_temp) * lwu(avg_temp)  * 
      clr_ratio(d_to_sol, day_of_year, lat)
  end

  # temperatures are in Celsius
  # avg_v_pressure is in kPa (kilopascals)
  # d_to_sol is insolation reading in MJ/day (Megajoules/day)
  # lat is latitude in fractional degrees
  def self.et(avg_temp, avg_v_press, d_to_sol, day_of_year, lat)
    lwnet = lwnet(avg_v_press, avg_temp, d_to_sol, day_of_year, lat)
    r_net_1 = (1.0 - ALBEDO) * d_to_sol - lwnet
    ret1 = 1.28 * sfactor(avg_temp) * r_net_1
    ret1 / 62.3
  end
end

