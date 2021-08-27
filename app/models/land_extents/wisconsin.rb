class Wisconsin < LandExtent

  def self.latitudes
    BigDecimal("42.0")..BigDecimal("47.1")
  end

  def self.longitudes
    BigDecimal("-93.1")..BigDecimal("-86.8")
  end

end
