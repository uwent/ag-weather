class AddDd32NoneToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :dd_32_none, :float
  end
end
