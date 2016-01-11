class CreateDataImports < ActiveRecord::Migration
  def change
    create_table :data_imports do |t|
      t.string   :data_type
      t.datetime :readings_from
      t.string   :status

      t.timestamps null: false
    end
  end
end
