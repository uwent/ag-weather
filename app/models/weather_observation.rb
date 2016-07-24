class WeatherObservation
  attr_accessor :temperature, :dew_point
  
  # assumes the data passed in is in Kelvin
  def initialize(temperature, dew_point)
    @temperature = temperature.nil? ? 0.0 : K_to_C(temperature)
    @dew_point = dew_point.nil? ? 0.0 : K_to_C(dew_point)
  end

  def relative_humidity
    100 * (Math.exp((17.625 * @dew_point) / (243.04 + @dew_point)) /
           Math.exp((17.625 * @temperature) / (243.04 + @temperature))).round(6)
  end

  def K_to_C(kelvin)
    kelvin - 273.15
  end
end
