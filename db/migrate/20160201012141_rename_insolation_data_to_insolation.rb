class RenameInsolationDataToInsolation < ActiveRecord::Migration
  def change
    rename_table :insolation_data, :insolations
  end
end
