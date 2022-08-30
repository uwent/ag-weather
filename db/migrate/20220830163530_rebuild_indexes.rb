class RebuildIndexes < ActiveRecord::Migration[7.0]
  def change
    [:evapotranspirations, :insolations, :pest_forecasts, :precips, :weather_data].each do |t|
      remove_index t, [:date, :latitude, :longitude], unique: true, if_exists: true
      remove_index t, [:latitude, :longitude], if_exists: true
      remove_index t, :longitude, if_exists: true

      add_index t, [:date, :latitude, :longitude], order: {date: :asc, latitude: :asc, longitude: :asc}, unique: true
      add_index t, [:latitude, :longitude], order: {latitude: :asc, longitude: :asc}
      add_index t, :longitude, order: {latitude: :asc}
    end
  end
end
