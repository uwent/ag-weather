class AddDd3875ToPestForecast < ActiveRecord::Migration[7.0]
  def change
    add_column :pest_forecasts, :dd_38_75, :float
  end
end
