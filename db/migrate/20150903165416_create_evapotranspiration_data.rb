class CreateEvapotranspirationData < ActiveRecord::Migration[6.0]
  def change
    create_table :evapotranspiration_data do |t|
      t.decimal :potential_et
      t.decimal :latitude, {:precision=>10, :scale=>6}
      t.decimal :longitude, {:precision=>10, :scale=>6}
      t.date    :date

      t.timestamps null: false
    end
  end
end
