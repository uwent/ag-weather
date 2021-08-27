class WiMn < LandExtent

  def self.latitudes
    BigDecimal("42.0")..BigDecimal("50.0")
  end

  def self.longitudes
    BigDecimal("-98.0")..BigDecimal("-86.0")
  end

end
