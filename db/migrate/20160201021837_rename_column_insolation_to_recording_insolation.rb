class RenameColumnInsolationToRecordingInsolation < ActiveRecord::Migration
  def change
    rename_column :insolations, :insolation, :recording
  end
end
