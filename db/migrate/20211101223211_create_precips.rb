class CreatePrecips < ActiveRecord::Migration[6.1]
  def change
    create_table :precips do |t|
      t.date :date
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.float :precip
    end
    
    add_index :precips, :date
    add_index :precips, [:latitude, :longitude]
    add_index :precips, [:date, :latitude, :longitude], unique: true
  end
end
