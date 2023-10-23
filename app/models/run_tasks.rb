module RunTasks
  def self.all
    start_time = Time.now
    ActiveRecord::Base.logger.level = :info
    DataImport.check_statuses

    # fetch remote data
    InsolationImporter.fetch
    PrecipImporter.fetch
    WeatherImporter.fetch

    # calculate local data
    EvapotranspirationImporter.create_data
    PestForecastImporter.create_data
    DegreeDayImporter.create_data

    # display status of import attempts
    ActiveRecord::Base.logger.level = Rails.configuration.log_level
    Rails.logger.info "Data tasks completed in #{DataImporter.elapsed(start_time)}"
    status = DataImport.check_statuses
    status&.count == 0
  end

  def self.create_latest_images(date = DataImporter.latest_date || Date.yesterday)
    images = []
    images << create_weather_images(date)
    images << create_precip_images(date)
    images << create_et_images(date)
    images << create_insol_images(date)
    images << DegreeDay.create_cumulative_image(start_date: date.beginning_of_year, end_date: date)
    images << PestForecast.create_image(date:)
    images
  end

  def self.create_weather_images(date = DataImporter.latest_date || Date.yesterday)
    images = []
    ["wi", "all"].each do |extent|
      ["F", "C"].each do |units|
        [:avg, :min, :max].each do |stat|
          col = "#{stat}_temp"
          images << Weather.create_image(date:, units:, extent:, col:, stat:)
          images << Weather.create_cumulative_image(start_date: date - 1.week, date:, units:, extent:, col:, stat:)
        end
      end
    end
    images
  end

  def self.create_precip_images(date = DataImporter.latest_date || Date.yesterday)
    images = []
    ["wi", "all"].each do |extent|
      ["in", "mm"].each do |units|
        images << Precip.create_image(date:, units:, extent:)
        [:sum, :avg, :max].each do |stat|
          images << Precip.create_cumulative_image(start_date: date - 1.week, date:, units:, extent:, stat:)
        end
      end
    end
  end

  def self.create_et_images(date = DataImporter.latest_date || Date.yesterday)
    images = []
    ["wi", "all"].each do |extent|
      ["in", "mm"].each do |units|
        images << Evapotranspiration.create_image(date:, units:, extent:)
        [:sum, :avg, :min, :max].each do |stat|
          images << Evapotranspiration.create_cumulative_image(start_date: date - 1.week, date:, units:, extent:, stat:)
        end
      end
    end
    images
  end

  def self.create_insol_images(date = DataImporter.latest_date || Date.yesterday)
    images = []
    ["wi", "all"].each do |extent|
      ["MJ", "KWh"].each do |units|
        images << Insolation.create_image(date:, units:, extent:)
        [:sum, :avg, :min, :max].each do |stat|
          images << Insolation.create_cumulative_image(start_date: date - 1.week, date:, units:, extent:, stat:)
        end
      end
    end
    images
  end

  def self.daily
    all
    create_latest_images
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
  # reports if Weather exists for each day in year
  def self.check_weather(year = Date.current.year)
    start_date = Date.new(year, 1, 1)
    end_date = [Date.new(year, 12, 31), Date.today].min
    dates = start_date..end_date
    msg = []
    missing = 0
    dates.each do |date|
      if Weather.where(date:).exists?
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
      Weather.create_image(date)
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
    (start_date..end_date).each { |date| Weather.create_image(date) }
  end

  def self.redo_et_images(start_date, end_date = Date.current)
    (start_date..end_date).each { |date| Evapotranspiration.create_image(date) }
  end

  def self.purge_old_images(delete: false)
    dir = ImageCreator.file_dir
    puts "\n### DAILY MAPS ###"
    purge_images(File.join(dir, "daily"), 1.month, delete)
    puts "\n### CUMULATIVE MAPS ###"
    purge_images(File.join(dir, "cumulative"), 1.week, delete)
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

  # re-generates pest forecasts for year from Weather
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

    weather = Weather.land_grid(date:)
    forecasts = []
    if weather.empty?
      puts date.strftime + " - no data"
      return
    end
    puts date.strftime + " - ready - recalculating..."
    LandExtent.each_point do |lat, long|
      next if weather[lat, long].nil?
      forecasts << PestForecast.new_from_weather(weather[lat, long])
    end
    PestForecast.transaction do
      PestForecast.where(date:).delete_all
      PestForecast.import(forecasts)
      PestForecastDataImport.succeed(date)
    end
  end

  # computed frost and freeze data for past weather when they were added to the db
  def self.calc_frost(start_date = Weather.earliest_date, end_date = Weather.latest_date)
    puts "Calculating freeze and frost data..."
    ActiveRecord::Base.logger.level = 1
    dates = start_date..end_date
    day = 0
    days = (start_date..end_date).count
    dates.each do |date|
      day += 1
      weather = Weather.where(date:).select(:latitude, :longitude)
      if weather.size > 0
        frosts = {}
        freezes = {}
        weather.where("min_temp < ?", 0.0).each { |w| frosts[[w.latitude, w.longitude]] = true }
        weather.where("min_temp < ?", -2.22).each { |w| freezes[[w.latitude, w.longitude]] = true }
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
  #     weather = Weather.where(date:)
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
