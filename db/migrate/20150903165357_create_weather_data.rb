class CreateWeatherData < ActiveRecord::Migration[6.0]
  def change
    create_table :weather_data do |t|
      t.decimal :max_temperature
      t.decimal :min_temperature
      t.decimal :avg_temperature
      t.decimal :vapor_pressure
      t.decimal :latitude, {precision: 10, scale: 6}
      t.decimal :longitude, {precision: 10, scale: 6}
      t.date :date

      t.timestamps null: false
    end
  end
end
