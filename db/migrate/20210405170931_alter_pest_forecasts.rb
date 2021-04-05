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
      t.remove :black_cutworm, :float
      t.remove :corn_rootworm, :float
      t.remove :european_corn_borer, :float
      t.remove :imported_cabbageworm, :float
      t.remove :japanese_beetle, :float
      t.remove :lygus_bug, :float
      t.remove :mint_root_borer, :float
      t.remove :seedcorn_maggot, :float
      t.remove :squash_vine_borer, :float
      t.remove :western_bean_cutworm, :float
    end
  end
end
