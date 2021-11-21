class AddFrostToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :frost, :boolean, default: false
    add_column :pest_forecasts, :freeze, :boolean, default: false
  end
end
