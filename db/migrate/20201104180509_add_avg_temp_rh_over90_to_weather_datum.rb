
class AddAvgTempRhOver90ToWeatherDatum < ActiveRecord::Migration[6.0]
  def change
    add_column :weather_data, :avg_temp_rh_over_90, :float
  end
end
