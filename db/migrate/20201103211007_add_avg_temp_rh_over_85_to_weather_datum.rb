
class AddAvgTempRhOver85ToWeatherDatum < ActiveRecord::Migration[6.0]
  def change
    add_column :weather_data, :avg_temp_rh_over_85, :float
  end
end
