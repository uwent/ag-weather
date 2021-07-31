class BigDecimalToFloat < ActiveRecord::Migration[6.1]
  def change
    change_column :pest_forecasts, :potato_p_days, :float
  end
end
