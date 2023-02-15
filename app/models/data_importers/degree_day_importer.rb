class DegreeDayImporter < DataImporter
  def self.import
    DegreeDayDataImport
  end

  def self.data_sources_loaded?(date)
    WeatherDataImport.successful.find_by(readings_on: date)
  end

  def self.daily_data_exists?(date)
    DegreeDay.daily.on(date).size == LandExtent.grid_size
  end

  def self.missing_dates(date = import.latest_date, cumulative: false)
    dates = date.beginning_of_year..date
    existing_dates = DegreeDay.where(cumulative:).on(dates).distinct.pluck(:date)

    return nil if dates.count == existing_dates.size

    missing_dates = []
    dates.each do |d|
      missing_dates << d.to_s unless existing_dates.include?(d)
    end
    Rails.logger.info "#{name} :: Missing #{missing_dates.size} degree days: #{missing_dates.join(', ')}."
    missing_dates
  end

  # create daily degree day values
  def self.create_data(date = DataImport.latest_date, force: false)
    missing_daily = missing_dates(date)
    missing_cumulative = missing_dates(date, cumulative: true)

    unless missing_daily || missing_cumulative
      Rails.logger.info "#{name} :: Everything's up to date, nothing to do!"
      return true
    end

    missing_daily.each do |date|
      create_data_for_date(date, force:)
    end

    missing_cumulative.each do |date|
      if daily_data_exists?(date)
        create_cumulative_for_date(date, force:) 
      else
        Rails.logger.info "#{name} :: Couldn't create cumulative data for #{date}, missing degree days."
      end
    end
  end

  def self.create_data_for_date(date, force: false)
    date = date.to_date
    raise StandardError.new("Weather data missing.") unless data_sources_loaded?(date)
    if data_exists?(date) && !force
      Rails.logger.info "#{name} :: Data already exists for #{date}, overwrite with force: true"
      return true
    end

    Rails.logger.info "#{name} :: Calculating degree day data for #{date}"
    start_time = Time.now
    import.start(date)

    # create daily data
    weather = WeatherDatum.all_for_date(date)
    dds = []
    weather.each do |w|
      dds << DegreeDay.new_from_weather(w)
    end

    DegreeDay.on(date).delete_all
    DegreeDay.import!(dds)
    import.succeed(date)

    Rails.logger.info "#{name} :: Completed degree day calculation for #{date} in #{elapsed(start_time)}."
  rescue => e
    msg = "Failed to calculate degree days for #{date}: #{e.message}"
    Rails.logger.error "#{name} :: #{msg}"
    import.fail(date, msg)
    false
  end

  def self.create_cumulative_for_date(date, force: false)
    date = date.to_date
    dates = date.beginning_of_year..date

    sql = DegreeDay.model_names.collect do |model|
      "sum(#{model}) as #{model}"
    end.join(", ")

    cum_dds = DegreeDay.daily.on(dates)
      .group(:latitude, :longitude)
      .order(:latitude, :longitude)
      .select(:latitude, :longitude, sql).collect do |point|
        attrs = point.attributes.compact
        attrs[:date] = date
        attrs[:cumulative] = true
        DegreeDay.new(attrs)
      end
    
    DegreeDay.cumulative.on(date).delete_all
    DegreeDay.import!(cum_dds)
    import.succeed(date)
    true
  rescue => e
    msg = "Failed to calculate cumulative degree days for #{date}: #{e.message}"
    Rails.logger.error "#{name} :: #{msg}"
    import.fail(date, msg)
    false
  end
end
