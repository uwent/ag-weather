class AddIndexesToTables < ActiveRecord::Migration[6.1]
  def change
    add_index :evapotranspirations, [:latitude, :longitude]
    add_index :insolations, [:latitude, :longitude]
    add_index :pest_forecasts, [:latitude, :longitude]
    add_index :weather_data, [:latitude, :longitude]

    add_index :evapotranspirations, :date
    add_index :insolations, :date
    add_index :pest_forecasts, :date
    add_index :weather_data, :date

    add_index :evapotranspirations, [:date, :latitude, :longitude], unique: true
    add_index :insolations, [:date, :latitude, :longitude], unique: true
    add_index :pest_forecasts, [:date, :latitude, :longitude], unique: true
    add_index :weather_data, [:date, :latitude, :longitude], unique: true
  end
end
