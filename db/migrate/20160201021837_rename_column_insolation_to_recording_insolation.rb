class RenameColumnInsolationToRecordingInsolation < ActiveRecord::Migration[6.0]
  def change
    rename_column :insolations, :insolation, :recording
  end
end
