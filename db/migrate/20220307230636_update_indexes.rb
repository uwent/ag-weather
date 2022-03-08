class UpdateIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :data_imports, :readings_on, if_not_exists: true

    [:evapotranspirations, :insolations, :pest_forecasts, :precips, :weather_data].each do |t|
      remove_index t, :date
      remove_index t, [:latitude, :longitude, :date], unique: true
      add_index t, [:date, :latitude, :longitude], unique: true, if_not_exists: true
      add_index t, :longitude, if_not_exists: true
    end
  end
end
