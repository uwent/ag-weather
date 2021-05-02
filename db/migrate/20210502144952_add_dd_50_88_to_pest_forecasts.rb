class AddDd5088ToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :dd_50_88, :float
  end
end
