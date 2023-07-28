class WeatherObservation
  attr_accessor :temperature, :dew_point

  # assumes the data passed in is in Kelvin
  def initialize(temperature, dew_point)
    @temperature = UnitConverter.k_to_c(temperature)
    @dew_point = UnitConverter.k_to_c(dew_point)
  end

  def relative_humidity
    UnitConverter.compute_rh(@temperature, @dew_point)&.clamp(0.0, 100.0)
  end
end
