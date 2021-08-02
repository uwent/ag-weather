class AddIndexesToTables < ActiveRecord::Migration[6.1]
  def change
    add_index :evapotranspirations, [:latitude, :longitude], if_not_exists: true
    add_index :insolations, [:latitude, :longitude], if_not_exists: true
    add_index :pest_forecasts, [:latitude, :longitude], if_not_exists: true
    add_index :weather_data, [:latitude, :longitude], if_not_exists: true

    add_index :evapotranspirations, :date, if_not_exists: true
    add_index :insolations, :date, if_not_exists: true
    add_index :pest_forecasts, :date, if_not_exists: true
    add_index :weather_data, :date, if_not_exists: true

    add_index :evapotranspirations, [:latitude, :longitude, :date], unique: true, if_not_exists: true
    add_index :insolations, [:latitude, :longitude, :date], unique: true, if_not_exists: true
    add_index :pest_forecasts, [:latitude, :longitude, :date], unique: true, if_not_exists: true
    add_index :weather_data, [:latitude, :longitude, :date], unique: true, if_not_exists: true
  end
end
