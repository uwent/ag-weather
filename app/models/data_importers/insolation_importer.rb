class InsolationImporter < DataImporter
  extend GribMethods

  URL_BASE = "http://prodserv1.ssec.wisc.edu/insolation_high_res/INSOLEAST/INSOLEAST"

  def self.data_model
    Insolation
  end

  def self.import
    InsolationDataImport
  end

  def self.formatted_date(date)
    "#{date.year}#{date.yday.to_s.rjust(3, "0")}"
  end

  def self.fetch_day(date, **args)
    Rails.logger.info "#{name} :: Fetching insolation data for #{date}"
    start_time = Time.now
    import.start(date)
    url = "#{URL_BASE}.#{formatted_date(date)}"
    Rails.logger.info "InsolationImporter :: GET #{url}"
    response = HTTParty.get(url)
    import_insolation_data(response, date)
    Insolation.create_image(date:) unless Rails.env.test?
    Rails.logger.info "#{name} :: Completed insolation load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Unable to retrieve insolation data: #{e}"
    import.fail(date, e)
  end

  # longitudes are positive degrees west in data import
  def self.import_insolation_data(response, date)
    if response.lines[0..5].to_s.include?("404")
      raise StandardError.new "404 Not Found"
    end

    insolations = []
    response.body.each_line do |line|
      val, lat, long = line.split
      val = val.to_f / 100.0
      lat = lat.to_f
      long = long.to_f * -1
      next if val < 0
      next unless LandExtent.inside?(lat, long)
      insolations << Insolation.new(
        date:,
        latitude: lat,
        longitude: long,
        insolation: val
      )
    end

    Insolation.transaction do
      Insolation.where(date:).delete_all
      Insolation.import!(insolations)
      import.succeed(date)
    end
  end
end
