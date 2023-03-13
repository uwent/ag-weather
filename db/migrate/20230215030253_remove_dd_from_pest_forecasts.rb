class RemoveDdFromPestForecasts < ActiveRecord::Migration[7.0]
  def change
    cols = %i[
      dd_48_none
      dd_50_86
      dd_54_92
      dd_50_90
      dd_42p8_86
      dd_52_none
      dd_55_92
      dd_41_none
      dd_39p2_86
      dd_41_86
      dd_41_88
      dd_45_none
      dd_50_none
      dd_50_88
      dd_45_86
      dd_32_none
      dd_38_75
    ]

    cols.each do |c|
      remove_column :pest_forecasts, c, :float
    end

    remove_column :pest_forecasts, :frost, :boolean
    remove_column :pest_forecasts, :freeze, :boolean
  end
end
