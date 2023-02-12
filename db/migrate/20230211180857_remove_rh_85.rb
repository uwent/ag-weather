class RemoveRh85 < ActiveRecord::Migration[7.0]
  def change
    remove_column :weather_data, :avg_temp_rh_over_85, :float
    remove_column :weather_data, :hours_rh_over_85, :integer
  end
end
