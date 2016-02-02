class RenameEvapotranspirationDataToEvapotranspiration < ActiveRecord::Migration
  def change
    rename_table :evapotranspiration_data, :evapotranspirations
  end
end
