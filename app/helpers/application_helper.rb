module ApplicationHelper
  # convert celcius to fahrenheit
  def c_to_f(c)
    c.to_f * 9.0 / 5.0 + 32.0
  end

  # convert fahrenheit to celcius
  def f_to_c(f)
    (f.to_f - 32.0).to_f * 5.0 / 9.0
  end

  # convert celcius degree days to fahrenheit degree days
  def cdd_to_fdd(cdd)
    cdd.to_f * 9.0 / 5.0
  end

  # convert fahrenheit degree days to celcius degree days
  def fdd_to_cdd(fdd)
    fdd.to_f * 5.0 / 9.0
  end

  def to_csv(data, headers = nil)
    CSV.generate do |csv|
      if headers
        headers.each { |h| csv << [h[0], h[1]] }
        csv << []
      end
      csv << data.first.keys
      data.each do |h|
        csv << h.values
      end
    rescue
    end
  end
end
