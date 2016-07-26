class CreatePestForecasts < ActiveRecord::Migration
  def change
    create_table :pest_forecasts do |t|
      t.date    :date
      t.decimal :latitude, { precision: 10, scale: 6 }
      t.decimal :longitude, { precision: 10, scale: 6 }
      t.integer :potato_blight_dsv, default: 0
      t.integer :carrot_foliar_dsv, default: 0

      t.timestamps null: false
    end
  end
end
