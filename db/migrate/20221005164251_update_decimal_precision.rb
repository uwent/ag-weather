class UpdateDecimalPrecision < ActiveRecord::Migration[7.0]
  # reduce lat/lon decimal precision from 10 to 5
  # precision <= 9 uses less bytes of memory
  # also enforce not null on lat/lon/date

  def tbls
    [
      :evapotranspirations,
      :insolations,
      :pest_forecasts,
      :precips,
      :weather_data,
      :stations
    ]
  end

  def up
    tbls.each do |t|
      change_column t, :latitude, :decimal, precision: 5, scale: 2, null: false
      change_column t, :longitude, :decimal, precision: 5, scale: 2, null: false
      if ActiveRecord::Base.connection.column_exists?(t, :date)
        change_column t, :date, :date, null: false
      end
    end
  end

  def down
  end
end
