class ChangeDataImportDate < ActiveRecord::Migration[7.0]
  def change
    rename_column :data_imports, :readings_on, :date
  end
end
