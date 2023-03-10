class WeatherObservation
  attr_accessor :temperature, :dew_point

  # assumes the data passed in is in Kelvin
  def initialize(temperature, dew_point)
    @temperature = temperature.nil? ? 0.0 : UnitConverter.k_to_c(temperature)
    @dew_point = dew_point.nil? ? 0.0 : UnitConverter.k_to_c(dew_point)
  end

  def relative_humidity
    UnitConverter.compute_rh(@temperature, @dew_point)
  end
end
