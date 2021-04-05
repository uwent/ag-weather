class AlterPestForecasts < ActiveRecord::Migration[6.1]
  def change
    change_table :pest_forecasts do |t|
      t.rename :onion_maggot, :dd_39p2_86
      t.rename :potato_psyllid, :dd_40_86
      t.rename :stalk_borer, :dd_41_86
      t.rename :variegated_cutworm, :dd_41_88
      t.rename :flea_beetle_mint, :dd_41_none
      t.rename :cabbage_maggot, :dd_42p8_86
      t.rename :western_flower_thrips, :dd_45_none
      t.rename :alfalfa_weevil, :dd_48_none
      t.rename :asparagus_beetle, :dd_50_86
      t.rename :cabbage_looper, :dd_50_90
      t.rename :flea_beetle_crucifer, :dd_50_none
      t.rename :colorado_potato_beetle, :dd_52_none
      t.rename :brown_marmorated_stink_bug, :dd_54_92
      t.rename :corn_earworm, :dd_55_92
    end
    remove_column :pest_forecasts, :black_cutworm, :float
    remove_column :pest_forecasts, :corn_rootworm, :float
    remove_column :pest_forecasts, :european_corn_borer, :float
    remove_column :pest_forecasts, :imported_cabbageworm, :float
    remove_column :pest_forecasts, :japanese_beetle, :float
    remove_column :pest_forecasts, :lygus_bug, :float
    remove_column :pest_forecasts, :mint_root_borer, :float
    remove_column :pest_forecasts, :seedcorn_maggot, :float
    remove_column :pest_forecasts, :squash_vine_borer, :float
    remove_column :pest_forecasts, :western_bean_cutworm, :float
  end
end
