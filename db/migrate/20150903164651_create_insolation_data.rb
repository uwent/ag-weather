class CreateInsolationData < ActiveRecord::Migration
  def change
    create_table :insolation_data do |t|
      t.decimal :insolation
      t.decimal :latitude, {:precision=>10, :scale=>6}
      t.decimal :longitude, {:precision=>10, :scale=>6}
      t.date    :date

      t.timestamps null: false
    end
  end
end
