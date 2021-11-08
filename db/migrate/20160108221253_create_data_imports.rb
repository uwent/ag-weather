class CreateDataImports < ActiveRecord::Migration[6.0]
  def change
    create_table :data_imports do |t|
      t.string :data_type, null: false
      t.date :readings_on, null: false
      t.string :status, null: false

      t.timestamps null: false
    end
  end
end
