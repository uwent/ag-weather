class AddFrostFreezeToWeatherData < ActiveRecord::Migration[7.0]
  def change
    add_column :weather_data, :frost, :boolean, as: "min_temperature <= 0", stored: true
    add_column :weather_data, :freeze, :boolean, as: "min_temperature <= -2.22", stored: true
  end
end
