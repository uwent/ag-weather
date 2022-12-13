class AddIndexesToDataImports < ActiveRecord::Migration[7.0]
  def change
    add_index :data_imports, :status
    add_index :data_imports, :updated_at
  end
end
