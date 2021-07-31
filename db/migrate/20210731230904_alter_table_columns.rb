class AlterTableColumns < ActiveRecord::Migration[6.1]
  def change
    change_table :evapotranspirations do |t|
      t.change :potential_et, :float
    end

    change_table :insolations do |t|
      t.rename :recording, :insolation
      t.change :insolation, :float
    end

    change_table :pest_forecasts do |t|
      t.change :potato_blight_dsv, :integer, default: nil
      t.change :carrot_foliar_dsv, :integer, default: nil
      t.change :cercospora_div, :integer, default: nil
      t.change :dd_50_88, :float, default: nil
      t.change :dd_45_86, :float, default: nil
    end

    change_table :weather_data do |t|
      t.change :max_temperature, :float
      t.change :min_temperature, :float
      t.change :avg_temperature, :float
      t.change :vapor_pressure, :float
      t.change :hours_rh_over_85, :integer, default: nil
    end

    change_table :stations do |t|
      t.change :latitude, :decimal, precision: 10, scale: 6
      t.change :longitude, :decimal, precision: 10, scale: 6
    end

  end
end
