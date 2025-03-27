class InsolationImporter < DataImporter
  extend GribMethods

  URL_BASE = "http://prodserv1.ssec.wisc.edu/insolation_high_res/INSOLEAST/INSOLEAST"

  def self.data_class
    Insolation
  end

  def self.import
    InsolationDataImport
  end

  def self.formatted_date(date)
    "#{date.year}#{date.yday.to_s.rjust(3, "0")}"
  end

  def self.fetch_day(date, **args)
    start_time = Time.now
    import.start(date)
    Rails.logger.info "#{name} :: Fetching insolation data for #{date}"
    response = get_from_http(date)
    import_insolation_data(response, date)
    Rails.logger.info "#{name} :: Completed insolation load for #{date} in #{elapsed(start_time)}."
  rescue => e
    Rails.logger.error "#{name} :: Unable to retrieve insolation data: #{e}"
    import.fail(date, e)
  end

  def self.get_from_http(date)
    url = "#{URL_BASE}.#{formatted_date(date)}"
    Rails.logger.info "InsolationImporter :: GET #{url}"
    response = HTTParty.get(url)
    raise StandardError.new "404 Not Found" if response.body.lines[0..5].to_s.include?("404")
    response
  end

  # longitudes are positive degrees west in data import
  def self.import_insolation_data(response, date)
    insols = []
    response.body.each_line do |line|
      val, lat, lng = line.split
      insolation = val.to_f / 100.0
      latitude = lat.to_f
      longitude = lng.to_f * -1
      next if insolation < 0
      next unless LandExtent.inside?(latitude, longitude)
      insols << Insolation.new(date:, latitude:, longitude:, insolation:)
    end

    Insolation.transaction do
      Insolation.where(date:).delete_all
      Insolation.import!(insols)
      import.succeed(date)
    end
  end

  def self.fetch_custom(date, url, force: false)
    date = date.to_date
    if Insolation.where(date:).exists?
      return Rails.logger.warn "Insolation already exists for #{date}, use force: true to overwrite"
    end
    response = HTTParty.get(url)
    import_insolation_data(response, date)
  rescue => e
    Rails.logger.error "#{name} :: Unable to retrieve insolation data: #{e}"
  end
end
