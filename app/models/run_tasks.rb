class RunTasks

  def self.all
    # fetch insolation data from SSEC server
    InsolationImporter.fetch

    # fetch weather data from NOAA server
    WeatherImporter.fetch

    # generate ETs from WeatherDatum and Insolation databases
    EvapotranspirationImporter.create_et_data

    # generate pest forecasts for VDIFN from WeatherDatum
    PestForecastImporter.create_forecast_data

    # generate ET image
    Evapotranspiration.create_and_static_link_image

    DataImport.check_statuses
  end

  def self.daily
    begin
      RunTasks.all
      DataImport.send_status_email
    rescue => e
      status = DataImport.check_statuses
      status[:message] << "ERROR: #{e.message}"
      StatusMailer.daily_mail(status[:message]).deliver
    end
  end

  ## Command-line tools ##
  # reports if WeatherDatum exists for each day in year
  def self.check_weather(year)
    start_date = Date.new(year, 1, 1)
    end_date = [Date.new(year, 12, 31), Date.today].min
    dates = start_date..end_date
    dates.each do |date|
      if WeatherDatum.where(date: date).exists?
        puts date.strftime + " - ready"
      else
        puts date.strftime + " - no data"
      end
    end
  end

  # re-generates pest forecasts for year from WeatherDatum
  # can be run if new models are added
  def self.redo_forecasts(year)
    start_date = Date.new(year, 1, 1)
    end_date = [Date.new(year, 12, 31), Date.today].min
    dates = start_date..end_date
    dates.each { |date| redo_forecast(date) }
  end

  # re-generates pest forecasts for specific date range
  def self.redo_forecasts_for_range(start_date, end_date)
    dates = Date.parse(start_date)..Date.parse(end_date)
    dates.each { |date| redo_forecast(date) }
  end

  # re-generates pest forecast for date
  def self.redo_forecast(date)
    if WeatherDatum.where(date: date).exists?
      puts date.strftime + " - ready - recalculating..."

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
      PestForecastDataImport.succeed(date)
    else
      puts date.strftime + " - no data"
    end
  end
end
