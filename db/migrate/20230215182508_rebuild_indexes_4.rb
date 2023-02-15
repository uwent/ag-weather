class RebuildIndexes4 < ActiveRecord::Migration[7.0]
  def change
    [:evapotranspirations, :insolations, :pest_forecasts, :precips, :weather_data].each do |t|
      remove_index t, [:date, :latitude, :longitude], unique: true, if_exists: true
      remove_index t, [:latitude, :longitude], if_exists: true
      remove_index t, :date, if_exists: true
      remove_index t, :latitude, if_exists: true
      remove_index t, :longitude, if_exists: true

      add_index t, [:date, :latitude, :longitude], unique: true, name: "#{t}_unique_key"
      add_index t, :date
      add_index t, :latitude
      add_index t, :longitude
    end
  end

  def down
    [:evapotranspirations, :insolations, :pest_forecasts, :precips, :weather_data].each do |t|
      remove_index t, [:date, :latitude, :longitude], unique: true, name: "#{t}_unique_key", if_exists: true
      remove_index t, :date, if_exists: true
      remove_index t, :latitude, if_exists: true
      remove_index t, :longitude, if_exists: true
    end
  end
end
