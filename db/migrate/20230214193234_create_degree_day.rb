class CreateDegreeDay < ActiveRecord::Migration[7.0]
  def change
    cols = %i[
      dd_32
      dd_38_75
      dd_39p2_86
      dd_41
      dd_41_86
      dd_42p8_86
      dd_45
      dd_45_80p1
      dd_45_86
      dd_48
      dd_50
      dd_50_86
      dd_50_87p8
      dd_50_90
      dd_52
      dd_52_86
      dd_55_92
    ]

    create_table :degree_days do |t|
      t.date :date, null: false
      t.decimal :latitude, precision: 5, scale: 2, null: false
      t.decimal :longitude, precision: 5, scale: 2, null: false
      cols.each do |c|
        t.float c
      end
      t.index [:date, :latitude, :longitude], unique: true, name: "degree_days_unique_key"
      t.index :date
      t.index :latitude
      t.index :longitude
    end
  end
end
