class AddDd4586ToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :dd_45_86, :float
  end
end
