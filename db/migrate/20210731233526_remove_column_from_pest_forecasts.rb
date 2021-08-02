class RemoveColumnFromPestForecasts < ActiveRecord::Migration[6.1]
  def change
    remove_column :pest_forecasts, :dd_40_86
  end
end
