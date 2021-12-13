class RunTasks
  def self.all
    # fetch remote data
    InsolationImporter.fetch
    PrecipImporter.fetch
    WeatherImporter.fetch

    # generate new data
    EvapotranspirationImporter.create_et_data
    PestForecastImporter.create_forecast_data
    PestForecast.create_dd_map("dd_50_none")

    # display status of import attempts
    DataImport.check_statuses
  end

  def self.daily
    RunTasks.all
    DataImport.send_status_email
  rescue => e
    status = ["ERROR: Daily tasks failed to run with message: #{e.message}"]
    StatusMailer.status_mail(status).deliver
  end

  def self.all_for_date(date)
    InsolationImporter.fetch_day(date)
    PrecipImporter.fetch_day(date)
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
      Insolation.create_image(date)
      Precip.create_image(date)
      WeatherDatum.create_image(date)
      Evapotranspiration.create_image(date)
    end
  end

  def self.redo_insol_images(start_date, end_date = Date.current)
    (start_date..end_date).each { |date| Insolation.create_image(date) }
  end

  def self.redo_precip_images(start_date, end_date = Date.current)
    (start_date..end_date).each { |date| Precip.create_image(date) }
  end

  def self.redo_weather_images(start_date, end_date = Date.current)
    (start_date..end_date).each { |date| WeatherDatum.create_image(date) }
  end

  def self.redo_et_images(start_date, end_date = Date.current)
    (start_date..end_date).each { |date| Evapotranspiration.create_image(date) }
  end

  def self.purge_old_images(delete: false, age: 1.year)
    image_dir = ImageCreator.file_dir
    files = Dir[image_dir + "/*"]
    del_count = keep_count = 0
    files.each do |file|
      modified = File.mtime(file)
      del = (Time.current - modified) > age
      if del
        del_count += 1
        puts file + " << DELETE"
        FileUtils.rm(file) if delete
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
    ActiveRecord::Base.logger.level = 1

    if WeatherDatum.where(date: date).size > 0
      puts date.strftime + " - ready - recalculating..."

      weather = WeatherDatum.land_grid_for_date(date)
      forecasts = []

      LandExtent.each_point do |lat, long|
        next unless LandExtent.inside?(lat, long)
        next if weather[lat, long].nil?
        forecasts << PestForecast.new_from_weather(weather[lat, long])
      end

      PestForecast.transaction do
        PestForecast.where(date: date).delete_all
        PestForecast.import(forecasts)
      end
      PestForecastDataImport.succeed(date)
    else
      puts date.strftime + " - no data"
    end
  end

  def self.calc_frost(start_date = WeatherDatum.earliest_date, end_date = WeatherDatum.latest_date)
    puts "Calculating freeze and frost data..."
    ActiveRecord::Base.logger.level = 1
    dates = start_date..end_date
    day = 0
    days = (start_date..end_date).count
    dates.each do |date|
      day += 1
      weather = WeatherDatum.where(date: date).select(:latitude, :longitude)
      if weather.size > 0
        frosts = {}
        freezes = {}
        weather.where("min_temperature < ?", 0.0).each { |w| frosts[[w.latitude, w.longitude]] = true }
        weather.where("min_temperature < ?", -2.22).each { |w| freezes[[w.latitude, w.longitude]] = true }
        frost_ids = []
        freeze_ids = []
        PestForecast.where(date: date).each do |pf|
          frost_ids << pf.id if frosts[[pf.latitude, pf.longitude]]
          freeze_ids << pf.id if freezes[[pf.latitude, pf.longitude]]
        end
        PestForecast.where(id: frost_ids.sort).update_all(frost: true)
        PestForecast.where(id: freeze_ids.sort).update_all(freeze: true)
        puts "Day #{day}/#{days}: #{date} ==> OK (frost #{sprintf("%.0f", frosts.size.to_f / weather.size * 100)}%, freeze #{sprintf("%.0f", freezes.size.to_f / weather.size * 100)}%)"
      else
        puts "Day #{day}/#{days}: #{date} ==> No data"
      end
    end
  end
end
