class ChangePotentialEtInEvapotranspirations < ActiveRecord::Migration[6.1]
  def change
    change_column :evapotranspirations, :potential_et, :decimal, :precision => 10, :scale => 6
  end
end
