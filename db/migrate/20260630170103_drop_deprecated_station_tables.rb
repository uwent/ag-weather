class DropDeprecatedStationTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :station_hourly_observations
    drop_table :stations
  end
end
