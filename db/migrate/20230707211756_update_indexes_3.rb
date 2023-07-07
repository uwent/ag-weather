class UpdateIndexes3 < ActiveRecord::Migration[7.0]
  def up
    # remove old indexes
    remove_index :data_imports, :updated_at, if_exists: true
    [:degree_days, :evapotranspirations, :insolations, :pest_forecasts, :precips, :weather].each do |t|
      remove_index t, [:date, :latitude, :longitude], unique: true, name: "#{t}_unique_key", if_exists: true
      remove_index t, [:latitude, :longitude], if_exists: true
      remove_index t, :date, if_exists: true
      remove_index t, :latitude, if_exists: true
      remove_index t, :longitude, if_exists: true

      # build fresh indexes
      add_index t, [:date, :latitude, :longitude], unique: true, name: "index_#{t}_on_date_lat_long"
      add_index t, [:latitude, :longitude], name: "index_#{t}_on_lat_long"
    end
  end

  def down
    [:degree_days, :evapotranspirations, :insolations, :pest_forecasts, :precips, :weather].each do |t|
      remove_index t, [:date, :latitude, :longitude], unique: true, name: "index_#{t}_on_date_lat_long", if_exists: true
      remove_index t, [:latitude, :longitude], name: "index_#{t}_on_lat_long", if_exists: true
    end
  end
end
