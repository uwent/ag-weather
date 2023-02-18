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

  # convert Megajoules to Kilowatt hours
  def self.mj_to_kwh(mj)
    return if mj.nil?
    mj.to_f / 3.6
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
end
