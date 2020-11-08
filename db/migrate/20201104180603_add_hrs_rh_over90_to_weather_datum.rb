class AddHrsRhOver90ToWeatherDatum < ActiveRecord::Migration
  def change
    add_column :weather_data, :hours_rh_over_90, :integer
  end
end
