class UpdateIndexes2 < ActiveRecord::Migration[7.0]
  def change
    [:evapotranspirations, :insolations, :pest_forecasts, :precips, :weather_data].each do |t|
      add_index t, [:date, :latitude, :longitude], unique: true, if_not_exists: true
      add_index t, :date, if_not_exists: true
      add_index t, :latitude, if_not_exists: true
      add_index t, :longitude, if_not_exists: true
    end
  end
end
