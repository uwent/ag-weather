class InsolationImporter
  URL_BASE = "http://prodserv1.ssec.wisc.edu/insolation_high_res/INSOLEAST/INSOLEAST"

  def self.fetch
    InsolationDataImport.days_to_load.each do |date|
      fetch_day(date)
    end
  end

  def self.formatted_date(date)
    "#{date.year}#{date.yday.to_s.rjust(3, "0")}"
  end

  def self.fetch_day(date)
    InsolationDataImport.start(date)
    Rails.logger.info "InsolationImporter :: Fetching insolation data for #{date}"

    begin
      url = "#{URL_BASE}.#{formatted_date(date)}"
      Rails.logger.info "GET #{url}"
      response = HTTParty.get(url)
      import_insolation_data(response, date)
    rescue => e
      msg = "Unable to retrieve insolation data: #{e.message}"
      Rails.logger.warn "InsolationImporter :: #{msg}"
      InsolationDataImport.fail(date, msg)
      msg
    end
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
        date: date,
        latitude: lat,
        longitude: long,
        insolation: val
      )
    end

    Insolation.transaction do
      Insolation.where(date: date).delete_all
      Insolation.import(insolations)
    end

    InsolationDataImport.succeed(date)
    Insolation.create_image(date)
  end
end
