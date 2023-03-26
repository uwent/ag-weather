class ChangeWeatherDataToWeather < ActiveRecord::Migration[7.0]
  def change
    rename_table :weather_data, :weather
  end
end
