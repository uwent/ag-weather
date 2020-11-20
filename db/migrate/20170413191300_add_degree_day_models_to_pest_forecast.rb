class AddDegreeDayModelsToPestForecast < ActiveRecord::Migration[6.0]
  def change
    add_column :pest_forecasts, :alfalfa_weevil, :float
    add_column :pest_forecasts, :asparagus_beetle, :float
    add_column :pest_forecasts, :black_cutworm, :float
    add_column :pest_forecasts, :brown_marmorated_stink_bug, :float
    add_column :pest_forecasts, :cabbage_looper, :float
    add_column :pest_forecasts, :cabbage_maggot, :float
    add_column :pest_forecasts, :colorado_potato_beetle, :float
    add_column :pest_forecasts, :corn_earworm, :float
    add_column :pest_forecasts, :corn_rootworm, :float
    add_column :pest_forecasts, :european_corn_borer, :float
    add_column :pest_forecasts, :flea_beetle_mint, :float
    add_column :pest_forecasts, :flea_beetle_crucifer, :float
    add_column :pest_forecasts, :imported_cabbageworm, :float
    add_column :pest_forecasts, :japanese_beetle, :float
    add_column :pest_forecasts, :lygus_bug, :float
    add_column :pest_forecasts, :mint_root_borer, :float
    add_column :pest_forecasts, :onion_maggot, :float
    add_column :pest_forecasts, :potato_psyllid, :float
    add_column :pest_forecasts, :seedcorn_maggot, :float
    add_column :pest_forecasts, :squash_vine_borer, :float
    add_column :pest_forecasts, :stalk_borer, :float
    add_column :pest_forecasts, :variegated_cutworm, :float
    add_column :pest_forecasts, :western_bean_cutworm, :float
    add_column :pest_forecasts, :western_flower_thrips, :float
  end
end
