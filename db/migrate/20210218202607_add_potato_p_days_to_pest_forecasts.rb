class AddPotatoPDaysToPestForecasts < ActiveRecord::Migration[6.1]
  def change
    add_column :pest_forecasts, :potato_p_days, :float
  end
end
