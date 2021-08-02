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

    add_index :evapotranspirations, [:latitude, :longitude, :date], unique: true
    add_index :insolations, [:latitude, :longitude, :date], unique: true
    add_index :pest_forecasts, [:latitude, :longitude, :date], unique: true
    add_index :weather_data, [:latitude, :longitude, :date], unique: true
  end
end
