class ChangeDataTypeToTypeInDataImport < ActiveRecord::Migration[6.0]
  def change
    rename_column :data_imports, :data_type, :type
  end
end
