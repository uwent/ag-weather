class ChangeRecordingInInsolations < ActiveRecord::Migration[6.1]
  def change
    rename_column :insolations, :recording, :insolation
    change_column :insolations, :insolation, :decimal, :precision => 10, :scale => 6
  end
end
