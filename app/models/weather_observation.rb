class WeatherObservation
  attr_accessor :temperature, :dew_point
  
  # assumes the data passed in is in Kelvin
  def initialize(temperature, dew_point)
    @temperature = temperature.nil? ? 0.0 : k_to_c(temperature)
    @dew_point = dew_point.nil? ? 0.0 : k_to_c(dew_point)
  end

  def relative_humidity
    dp = (17.625 * @dew_point) / (243.04 + @dew_point)
    temp = (17.625 * @temperature) / (243.04 + @temperature)
    (100 * (Math.exp(dp) / Math.exp(temp))).round(6)
  end

  def k_to_c(kelvin)
    kelvin - 273.15
  end
end
