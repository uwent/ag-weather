module UnitConverter
  # convert celsius to fahrenheit
  def self.c_to_f(c)
    return if c.nil?
    c.to_f * 1.8 + 32
  end

  # convert fahrenheit to celsius
  def self.f_to_c(f)
    return if f.nil?
    (f.to_f - 32.0) * 5.0 / 9.0
  end

  # kelvin to celsius
  def self.k_to_c(k)
    return if k.nil?
    k - 273.15
  end

  # convert celsius degree days to fahrenheit degree days
  def self.cdd_to_fdd(cdd)
    return if cdd.nil?
    cdd.to_f * 1.8
  end

  # convert fahrenheit degree days to celsius degree days
  def self.fdd_to_cdd(fdd)
    return if fdd.nil?
    fdd.to_f * 5.0 / 9.0
  end

  # inches to mm
  def self.in_to_mm(inches)
    return if inches.nil?
    inches.to_f * 25.4
  end

  # mm to inches
  def self.mm_to_in(mm)
    return if mm.nil?
    mm.to_f / 25.4
  end

  # convert Megajoules to Kilowatt hours
  def self.mj_to_kwh(mj)
    return if mj.nil?
    mj.to_f / 3.6
  end

  # temperature in celsius
  # vapor pressure in kPa
  # https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
  # dew point temperature yields actual vapor pressure
  # air temperature yields saturated vapor pressure
  def self.temp_to_vp(td)
    return if td.nil?
    exp = (7.5 * td) / (237.3 + td)
    mbar = 6.105 * 10**exp
    mbar / 10 # kPa
  end

  # yields relative humidity (%) from temperature and dew point
  # temperatures in celsius
  def self.compute_rh(t, td)
    return if t.nil? || td.nil?
    e = temp_to_vp(td) # actual vapor pressure
    es = temp_to_vp(t) # saturated vapor pressure
    e / es * 100
  end

  # equation source: https://bmcnoldy.rsmas.miami.edu/Humidity.html
  # def relative_humidity
  #   dp = Math.exp((17.625 * @dew_point) / (243.04 + @dew_point))
  #   t = Math.exp((17.625 * @temperature) / (243.04 + @temperature))
  #   100 * (dp / t)
  # end

  # def self.dew_point_to_vapor_pressure(dew_point)
  #   # units in: dew point in Celsius
  #   vapor_p_mb = 6.105 * Math.exp((2500000.0 / 461.0) * ((1.0 / 273.16) - (1.0 / (dew_point + 273.15))))
  #   vapor_p_mb / 10
  # end
end
