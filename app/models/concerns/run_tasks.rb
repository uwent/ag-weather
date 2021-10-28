module RunTasks

  def self.all
    # fetch insolation data from SSEC server
    InsolationImporter.fetch

    # fetch weather data from NOAA server
    WeatherImporter.fetch

    # generate ETs from WeatherDatum and Insolation databases
    EvapotranspirationImporter.create_et_data

    # generate pest forecasts for VDIFN from WeatherDatum
    PestForecastImporter.create_forecast_data

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

  def self.all_for_date(date)
    InsolationImporter.fetch_day(date)
    WeatherImporter.fetch_day(date)
    EvapotranspirationImporter.calculate_et_for_date(date)
    PestForecastImporter.calculate_forecast_for_date(date)
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

  # re-generates map images for specific dates
  def self.redo_images(start_date, end_date = Date.current)
    dates = start_date..end_date
    dates.each do |date|
      WeatherDatum.create_image(date)
      Insolation.create_image(date)
      Evapotranspiration.create_image(date)
    end
  end

  def self.redo_weather_images(start_date, end_date = Date.current)
    dates = start_date..end_date
    dates.each do |date|
      WeatherDatum.create_image(date)
    end
  end

  def self.redo_insol_images(start_date, end_date = Date.current)
    dates = start_date..end_date
    dates.each do |date|
      Insolation.create_image(date)
    end
  end

  def self.redo_et_images(start_date, end_date = Date.current)
    dates = start_date..end_date
    dates.each do |date|
      Evapotranspiration.create_image(date)
    end
  end

  def self.purge_old_images(delete: false, age: 1.year)
    image_dir = ImageCreator.file_path
    files = Dir[image_dir + "/*"]
    del_count = keep_count = 0
    files.each do |file|
      modified = File.mtime(file)
      del = (Time.current - modified) > age
      if del
        del_count += 1
        puts file + " << DELETE"
        File.rm(file) if delete
      else
        keep_count += 1
        puts file + " -- keep"
      end
    end
    puts "Keep: #{keep_count}, Delete: #{del_count}"
    puts "Run with 'delete: true' to permanently delete image files." if delete == false
    del_count
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

      LandExtent.each_point do |lat, long|
        next unless LandExtent.inside?(lat, long)

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
