class RunTasks
  def self.all
    start_time = Time.now

    DataImport.check_statuses

    # fetch remote data
    InsolationImporter.fetch
    PrecipImporter.fetch
    WeatherImporter.fetch

    # calculate local data
    threads = []
    threads << Thread.new { EvapotranspirationImporter.create_data }
    threads << Thread.new { PestForecastImporter.create_data }
    threads << Thread.new { DegreeDayImporter.create_data }
    threads.each { |thr| thr.join }

    # create images
    Evapotranspiration.create_image
    PestForecast.create_image
    DegreeDay.create_image

    # display status of import attempts
    DataImport.check_statuses
    Rails.logger.info "Data tasks completed in #{DataImporter.elapsed(start_time)}"
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
  def self.check_weather(year = Date.current.year)
    start_date = Date.new(year, 1, 1)
    end_date = [Date.new(year, 12, 31), Date.today].min
    dates = start_date..end_date
    msg = []
    missing = 0
    dates.each do |date|
      if WeatherDatum.where(date:).exists?
        msg << "#{date} - ok"
      else
        msg << "#{date} - missing"
        missing += 1
      end
    end
    puts msg.join("\n")
    "Missing days: #{missing}"
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

  def self.purge_old_images(delete: false)
    puts "\n### DAILY MAPS ###"
    purge_images(ImageCreator.file_dir, 1.year, delete)
    puts "\n### PEST MAPS ###"
    purge_images(File.join(ImageCreator.file_dir, PestForecast.pest_map_dir), 1.week, delete)
  end

  def self.purge_images(dir, age, delete)
    files = Dir[dir + "/**/*"]
    del_count = keep_count = 0
    files.each do |file|
      modified = File.mtime(file)
      if (Time.current - modified) > age
        del_count += 1
        puts file + " << DELETE"
        FileUtils.rm(file) if delete
      else
        keep_count += 1
        puts file + " << keep"
      end
    end
    puts "Keep: #{keep_count}, Delete: #{del_count}"
    puts "Run with 'delete: true' to permanently delete image files." if delete == false
    del_count
  end

  # re-generates pest forecasts for year from WeatherDatum
  # can be run if new models are added
  def self.redo_forecasts(year = Date.current.year)
    start_date = Date.new(year, 1, 1)
    end_date = [Date.new(year, 12, 31), Date.today].min
    dates = start_date..end_date
    dates.each { |date| redo_forecast(date) }
  end

  # re-generates pest forecasts for specific date range
  def self.redo_forecasts_for_range(start_date = Date.current.beginning_of_year, end_date = Date.current)
    dates = Date.parse(start_date)..Date.parse(end_date)
    dates.each { |date| redo_forecast(date) }
  end

  # re-generates pest forecast for date
  def self.redo_forecast(date)
    ActiveRecord::Base.logger.level = 1

    if WeatherDatum.where(date:).size > 0
      puts date.strftime + " - ready - recalculating..."

      weather = WeatherDatum.land_grid_for_date(date)
      forecasts = []

      LandExtent.each_point do |lat, long|
        next unless LandExtent.inside?(lat, long)
        next if weather[lat, long].nil?
        forecasts << PestForecast.new_from_weather(weather[lat, long])
      end

      PestForecast.transaction do
        PestForecast.where(date:).delete_all
        PestForecast.import(forecasts)
      end
      PestForecastDataImport.succeed(date)
    else
      puts date.strftime + " - no data"
    end
  end

  # computed frost and freeze data for past weather when they were added to the db
  def self.calc_frost(start_date = WeatherDatum.earliest_date, end_date = WeatherDatum.latest_date)
    puts "Calculating freeze and frost data..."
    ActiveRecord::Base.logger.level = 1
    dates = start_date..end_date
    day = 0
    days = (start_date..end_date).count
    dates.each do |date|
      day += 1
      weather = WeatherDatum.where(date:).select(:latitude, :longitude)
      if weather.size > 0
        frosts = {}
        freezes = {}
        weather.where("min_temperature < ?", 0.0).each { |w| frosts[[w.latitude, w.longitude]] = true }
        weather.where("min_temperature < ?", -2.22).each { |w| freezes[[w.latitude, w.longitude]] = true }
        frost_ids = []
        freeze_ids = []
        PestForecast.where(date:).each do |pf|
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

  # this was sooooo slow
  # def self.fill_dd_38_75
  #   ActiveRecord::Base.logger.level = 1
  #   dates = PestForecast.select(:date).distinct.pluck(:date).to_a.sort
  #   dates.each do |date|
  #     puts date.to_s
  #     weather = WeatherDatum.where(date:)
  #     pfs = PestForecast.where(date: date)
  #     pfs.each do |pf|
  #       next unless pf.dd_38_75.nil?
  #       latitude = pf.latitude
  #       longitude = pf.longitude
  #       w = weather.where(latitude:, longitude:).first
  #       value = w.degree_days(38, 75)
  #       puts "  #{latitude}, #{longitude}: #{value.round(2)}"
  #       pf.update(dd_38_75: value)
  #     end
  #   end
  # end
end
