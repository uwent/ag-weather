class CreateStations < ActiveRecord::Migration[6.0]
  def change
    create_table :stations do |t|
      t.string :name, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
    end
  end
end
