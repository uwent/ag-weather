class ChangeTypeInDataImportAllowNull < ActiveRecord::Migration[6.0]
  def change
    change_column :data_imports, :type, :string, null: true
  end
end
