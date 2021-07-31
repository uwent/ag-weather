class ChangePestForecasts < ActiveRecord::Migration[6.1]
  def change
    change_table :pest_forecasts do |t|
      t.remove :dd_40_86
      t.change :potato_p_days, :decimal, :precision => 10, :scale => 6
      t.change :dd_50_88, :decimal, :precision => 10, :scale => 6, :default => nil
      t.change :dd_45_86, :decimal, :precision => 10, :scale => 6, :default => nil
    end
  end
end
