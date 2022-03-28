class UnitConverter
  # convert celsius to fahrenheit
  def self.c_to_f(c)
    c.to_f * 9.0 / 5.0 + 32
  end

  # convert fahrenheit to celsius
  def self.f_to_c(f)
    (f.to_f - 32.0) * 5.0 / 9.0
  end

  # convert celsius degree days to fahrenheit degree days
  def self.cdd_to_fdd(cdd)
    cdd.to_f * 9.0 / 5.0
  end

  # convert fahrenheit degree days to celsius degree days
  def self.fdd_to_cdd(fdd)
    fdd.to_f * 5.0 / 9.0
  end

  # convert Megajoules to Kilowatt hours
  def self.mj_to_kwh(mj)
    mj.to_f * (1 / 3.6)
  end

  # inches to mm
  def self.in_to_mm(inches)
    inches.to_f * 25.4
  end

  # mm to inches
  def self.mm_to_in(mm)
    mm.to_f / 25.4
  end
end
