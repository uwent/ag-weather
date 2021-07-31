class ChangePrecisionInWeatherData < ActiveRecord::Migration[6.1]
  def change
    change_table :weather_data do |t|
      t.change :max_temperature, :decimal, :precision => 10, :scale => 6
      t.change :min_temperature, :decimal, :precision => 10, :scale => 6
      t.change :avg_temperature, :decimal, :precision => 10, :scale => 6
      t.change :vapor_pressure, :decimal, :precision => 10, :scale => 6
      t.change :avg_temp_rh_over_85, :decimal, :precision => 10, :scale => 6
      t.change :avg_temp_rh_over_90, :decimal, :precision => 10, :scale => 6
    end
  end
end
