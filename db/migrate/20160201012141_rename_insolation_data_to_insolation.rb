class RenameInsolationDataToInsolation < ActiveRecord::Migration[6.0]
  def change
    rename_table :insolation_data, :insolations
  end
end
