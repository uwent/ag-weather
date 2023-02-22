class AddFieldsToWeatherDatum < ActiveRecord::Migration[7.0]
  def change
    rename_column :weather_data, :max_temperature, :max_temp
    rename_column :weather_data, :min_temperature, :min_temp
    rename_column :weather_data, :avg_temperature, :avg_temp
    add_column :weather_data, :min_rh, :float
    add_column :weather_data, :max_rh, :float
    add_column :weather_data, :avg_rh, :float
  end
end
