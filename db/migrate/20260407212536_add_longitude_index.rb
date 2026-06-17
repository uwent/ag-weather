class AddLongitudeIndex < ActiveRecord::Migration[8.1]
  def change
    [:degree_days, :evapotranspirations, :insolations, :pest_forecasts, :precips, :weather].each do |t|
      add_index t, :longitude, name: "index_#{t}_on_longitude"
    end
  end
end
