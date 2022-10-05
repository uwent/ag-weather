class ChangeTimestamps < ActiveRecord::Migration[7.0]
  def up
    add_timestamps :stations, default: -> { 'now()' }, null: false
    [
      :evapotranspirations,
      :insolations,
      :pest_forecasts,
      :station_hourly_observations,
      :weather_data
    ].each do |t|
      remove_column t, :created_at
      remove_column t, :updated_at
    end
  end

  def down
  end
end
