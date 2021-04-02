class AddCercosporaToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :cercospora_div, :integer, :default => 0
  end
end
