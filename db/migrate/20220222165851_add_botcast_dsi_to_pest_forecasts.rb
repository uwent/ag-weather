class AddBotcastDsiToPestForecasts < ActiveRecord::Migration[7.0]
  def change
    add_column :pest_forecasts, :botcast_dsi, :integer, default: 0
  end
end
