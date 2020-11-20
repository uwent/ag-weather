class AddHoursRhOver85ToWeatherDatum < ActiveRecord::Migration[6.0]
  def change
    add_column :weather_data, :hours_rh_over_85, :integer, default: 0
  end
end
