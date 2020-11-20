class AddTimestampsToStationHourlyObservations < ActiveRecord::Migration[6.0]
  def change
    add_column :station_hourly_observations, :created_at, :datetime
    add_column :station_hourly_observations, :updated_at, :datetime
  end
end
