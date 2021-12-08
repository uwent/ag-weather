module UnitConverter
  # convert celcius to fahrenheit
  def self.c_to_f(c)
    c.to_f * 9.0 / 5.0 + 32
  end

  # convert fahrenheit to celcius
  def self.f_to_c(f)
    (f.to_f - 32.0) * 5.0 / 9.0
  end

  # convert celcius degree days to fahrenheit degree days
  def self.cdd_to_fdd(cdd)
    cdd.to_f * 9.0 / 5.0
  end

  # convert fahrenheit degree days to celcius degree days
  def self.fdd_to_cdd(fdd)
    fdd.to_f * 5.0 / 9.0
  end
end
