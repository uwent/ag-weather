class CreateDataImports < ActiveRecord::Migration
  def change
    create_table :completed_imports do |t|
      t.string   :type
      t.datetime :readings_from
      t.string   :status

      t.timestamps null: false
    end
  end
end
