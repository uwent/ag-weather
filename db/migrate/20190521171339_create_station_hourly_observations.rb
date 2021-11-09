class CreateStationHourlyObservations < ActiveRecord::Migration[6.0]
  def change
    create_table :station_hourly_observations do |t|
      t.integer :station_id
      t.date :reading_on
      t.integer :hour
      t.float :max_temperature
      t.float :min_temperature
      t.float :relative_humidity
    end
  end
end
