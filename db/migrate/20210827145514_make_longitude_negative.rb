class MakeLongitudeNegative < ActiveRecord::Migration[6.1]
  def change
    Evapotranspiration.update_all("longitude = longitude * -1")
    Insolation.update_all("longitude = longitude * -1")
    PestForecast.update_all("longitude = longitude * -1")
    WeatherDatum.update_all("longitude = longitude * -1")
  end
end
