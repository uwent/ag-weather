class UpdateIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :data_imports, :readings_on

    [:evapotranspirations, :insolations, :pest_forecasts, :weather_data].each do |t|
      remove_index t, :date
      remove_index t, [:latitude, :longitude, :date], unique: true
      add_index t, [:date, :latitude, :longitude], unique: true
      add_index t, :longitude
    end

    remove_index :precips, :date
    add_index :precips, :longitude
  end
end
