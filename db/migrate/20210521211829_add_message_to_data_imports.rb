class AddMessageToDataImports < ActiveRecord::Migration[6.1]
  def change
    add_column :data_imports, :message, :string
  end
end
