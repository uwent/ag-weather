class RenameEvapotranspirationDataToEvapotranspiration < ActiveRecord::Migration[6.0]
  def change
    rename_table :evapotranspiration_data, :evapotranspirations
  end
end
