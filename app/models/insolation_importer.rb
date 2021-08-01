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
      east_response = HTTParty.get(east_url)
      import_insolation_data(east_response, date)
      InsolationDataImport.succeed(date)
    rescue => e
      Rails.logger.warn "InsolationImporter :: Fetch day failed: #{e.message}"
      InsolationDataImport.fail(date, e.message)
    end
  end

  def self.import_insolation_data(http_response, date)
    insolations = []
    http_response.body.each_line do |line|
      row = line.split

      value = row[0].to_i
      lat = row[1].to_f
      long = row[2].to_f

      next if value == -99999
      next unless LandExtent.inside?(lat, long)

      insolations << Insolation.new(
        insolation: value/100.0,
        latitude: lat,
        longitude: long,
        date: date)
    end
    Insolation.where(date: date).delete_all
    Insolation.import(insolations, validate: false)
    Insolation.create_image(date)
  end

end
