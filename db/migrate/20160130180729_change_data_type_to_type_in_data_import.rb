class ChangeDataTypeToTypeInDataImport < ActiveRecord::Migration
  def change
    rename_column :data_imports, :data_type, :type
  end
end
