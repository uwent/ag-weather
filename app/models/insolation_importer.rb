class InsolationImporter

  def self.fetch_day(date)
    # http://prodserv1.ssec.wisc.edu/insolation/INSOLEAST/INSOLEAST.#{formatted_date(date)}




    InsolationDatum.create
    true
  end

  def self.formatted_date(date)
    "#{date.year}#{date.doy.to_s.rjust(3, '0')}"
  end
end