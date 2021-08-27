class InsolationImporter

  URL_BASE = "http://prodserv1.ssec.wisc.edu/insolation_high_res/INSOLEAST/INSOLEAST"

  def self.formatted_date(date)
    "#{date.year}#{date.yday.to_s.rjust(3, '0')}"
  end

  def self.fetch
    days_to_load = InsolationDataImport.days_to_load
    days_to_load.each { |day| InsolationImporter.fetch_day(day) }
  end

  def self.fetch_day(date)
    begin
      InsolationDataImport.start(date)
      east_url = "#{URL_BASE}.#{formatted_date(date)}"
      Rails.logger.info "InsolationImporter :: Fetching #{east_url}"
      east_response = HTTParty.get(east_url)
      import_insolation_data(east_response, date)
      InsolationDataImport.succeed(date)
    rescue => e
      Rails.logger.warn "InsolationImporter :: Fetch day failed: #{e.message}"
      InsolationDataImport.fail(date, e.message)
    end
    Insolation.create_image(date)
  end

  # longitudes are positive degrees west in data import
  def self.import_insolation_data(response, date)
    if response.lines[0..5].to_s.include?("404")
      raise StandardError.new "404 Not Found"
    end
    insolations = []
    response.body.each_line do |line|
      row = line.split
      value = row[0].to_i
      lat = row[1].to_f
      long = row[2].to_f * -1
      next if value < 0
      next unless LandExtent.inside?(lat, long)
      insolations << Insolation.new(
        insolation: value / 100.0,
        latitude: lat,
        longitude: long,
        date: date
      )
    end
    Insolation.where(date: date).delete_all
    Insolation.import(insolations, validate: false)
  end

end
