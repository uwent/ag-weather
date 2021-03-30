class RunTasks

  def self.all
    WeatherImporter.fetch
    InsolationImporter.fetch
    EvapotranspirationImporter.create_et_data
    PestForecastImporter.create_forecast_data
    Evapotranspiration.create_and_static_link_image
  end

  def self.check_weather(year)
    ActiveRecord::Base.logger.level = 1
    (Date.new(year, 01, 01)..[Date.new(year, 12, 31), Date.today].min).each do |date|
      if WeatherDatum.where(date: date).exists?
        puts date.strftime + " - ready"
      else
        puts date.strftime + " - no data"
      end
    end
    ActiveRecord::Base.logger.level = 0
  end

  def self.redo_forecasts(year)
    ActiveRecord::Base.logger.level = 1
    (Date.new(year, 1, 1)..[Date.new(year, 12, 31), Date.today].min).each do |date|
      redo_forecast(date)
    end
    ActiveRecord::Base.logger.level = 0
  end

  def self.redo_forecast(date)
    if WeatherDatum.where(date: date).exists?
      puts date.strftime + " - recalculating..."

      weather = WeatherDatum.land_grid_for_date(date)
      forecasts = []

      Wisconsin.each_point do |lat, long|
        next unless Wisconsin.inside?(lat, long)

        if weather[lat, long].nil?
          Rails.logger.error("Failed to calculate pest forcast for #{date}, lat: #{lat} long: #{long}.")
          next
        end

        forecasts << PestForecast.new_from_weather(weather[lat, long])
      end

      PestForecast.where(date: date).delete_all
      PestForecast.import(forecasts, validate: false)
      PestForecastDataImport.where(readings_on: date).delete_all
      PestForecastDataImport.create_successful_load(date)
    else
      puts date.strftime + " - no weather data"
    end
  end
end
