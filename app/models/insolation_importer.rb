class InsolationImporter

  def self.fetch_day(date)
    # http://prodserv1.ssec.wisc.edu/insolation/INSOLEAST/INSOLEAST.#{formatted_date(date)}
    response = HTTParty.get(east_url)

    response.body.each_line do |line|
      row = line.split

      value = row[0]
      lat = row[1]
      long = row[2]

      next if value == -99999
      next if outside_wi_box?(lat, long)

      InsolationDatum.create(
        insolation: row[0],
        latitude: row[1],
        longitude: row[2],
        date: date
      )
    end



    InsolationDatum.create
    true
  end

  def self.formatted_date(date)
    "#{date.year}#{date.doy.to_s.rjust(3, '0')}"
  end

  def self.outside_wi_box?(lat, long) #TODO: include MN in this box
    (lat > 42 && lat < 48) && (long > 86 && long < 93)
  end
end
