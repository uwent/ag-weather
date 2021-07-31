class BigDecimalBackToFloat < ActiveRecord::Migration[6.1]
  def change
    change_table :evapotranspirations do |t|
      t.change :potential_et, :float
    end

    change_table :insolations do |t|
      t.change :insolation, :float
    end

    change_table :weather_data do |t|
      t.change :max_temperature, :float
      t.change :min_temperature, :float
      t.change :avg_temperature, :float
      t.change :vapor_pressure, :float
      t.change :avg_temp_rh_over_85, :float
      t.change :avg_temp_rh_over_90, :float
    end

    change_table :pest_forecasts do |t|
      t.change :dd_39p2_86, :float
      t.change :dd_41_86, :float
      t.change :dd_41_88, :float
      t.change :dd_41_none, :float
      t.change :dd_42p8_86, :float
      t.change :dd_45_none, :float
      t.change :dd_45_86, :float
      t.change :dd_48_none, :float
      t.change :dd_50_86, :float
      t.change :dd_50_88, :float
      t.change :dd_50_90, :float
      t.change :dd_50_none, :float
      t.change :dd_52_none, :float
      t.change :dd_54_92, :float
      t.change :dd_55_92, :float
    end
  end
end
