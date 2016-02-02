class ChangeTypeInDataImportAllowNull < ActiveRecord::Migration
  def change
    change_column :data_imports, :type, :string, null: true
  end
end
