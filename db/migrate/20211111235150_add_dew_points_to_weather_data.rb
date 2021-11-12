class AddDewPointsToWeatherData < ActiveRecord::Migration[6.1]
  def change
    add_column :weather_data, :dew_point, :float
  end
end
