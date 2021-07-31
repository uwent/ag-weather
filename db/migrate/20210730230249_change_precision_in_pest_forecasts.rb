class ChangePrecisionInPestForecasts < ActiveRecord::Migration[6.1]
  def change
    change_table :pest_forecasts do |t|
      t.change :cercospora_div, :integer, after: :carrot_foliar_dsv
      t.change :dd_39p2_86, :decimal, :precision => 10, :scale => 6
      t.change :dd_41_86, :decimal, :precision => 10, :scale => 6
      t.change :dd_41_88, :decimal, :precision => 10, :scale => 6
      t.change :dd_41_none, :decimal, :precision => 10, :scale => 6
      t.change :dd_42p8_86, :decimal, :precision => 10, :scale => 6
      t.change :dd_45_none, :decimal, :precision => 10, :scale => 6
      t.change :dd_45_86, :decimal, :precision => 10, :scale => 6
      t.change :dd_48_none, :decimal, :precision => 10, :scale => 6
      t.change :dd_50_86, :decimal, :precision => 10, :scale => 6
      t.change :dd_50_88, :decimal, :precision => 10, :scale => 6
      t.change :dd_50_90, :decimal, :precision => 10, :scale => 6
      t.change :dd_50_none, :decimal, :precision => 10, :scale => 6
      t.change :dd_52_none, :decimal, :precision => 10, :scale => 6
      t.change :dd_54_92, :decimal, :precision => 10, :scale => 6
      t.change :dd_55_92, :decimal, :precision => 10, :scale => 6
    end
  end
end
