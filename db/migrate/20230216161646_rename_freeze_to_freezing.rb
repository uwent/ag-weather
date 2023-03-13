class RenameFreezeToFreezing < ActiveRecord::Migration[7.0]
  def change
    remove_column :weather_data, :frost, :boolean
    remove_column :weather_data, :freeze, :boolean
    add_column :weather_data, :frost, :integer, as: "(min_temperature < 0)::int", stored: true
    add_column :weather_data, :freezing, :integer, as: "(min_temperature < -2)::int", stored: true
  end
end
