class InsolationImporter

  def self.fetch
    days_to_load = DataImport.days_to_load_for('insolation')

    days_to_load.each do |day|
      InsolationImporter.fetch_day(day)
    end
  end

  def self.fetch_day(date)
    east_url = "http://prodserv1.ssec.wisc.edu/insolation/INSOLEAST/INSOLEAST.#{formatted_date(date)}"
    west_url = "http://prodserv1.ssec.wisc.edu/insolation/INSOLWEST/INSOLWEST.#{formatted_date(date)}"

    east_response = HTTParty.get(east_url)
    import_insolation_data(east_response,date)

    west_response = HTTParty.get(west_url)
    import_insolation_data(west_response,date)

    DataImport.loaded_successfully('insolation', date)
  end

  def self.import_insolation_data(http_response,date)
    http_response.body.each_line do |line|
      row = line.split

      value = row[0].to_i
      lat = row[1].to_f
      long = row[2].to_f

      next if value == -99999
      next if !inside_wi_mn_box?(lat, long)

      InsolationDatum.create(
        insolation: row[0],
        latitude: row[1],
        longitude: row[2],
        date: date
      )
    end
  end

  def self.formatted_date(date)
    "#{date.year}#{date.yday.to_s.rjust(3, '0')}"
  end

  def self.inside_wi_mn_box?(lat, long)
    (lat > 42 && lat < 50) && (long > 86 && long < 98)
  end
end
