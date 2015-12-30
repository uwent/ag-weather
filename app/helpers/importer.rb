class Importer

  def self.save_files
    client = Net::FTP.new('ftp.ncep.noaa.gov')
    client.login
    client.passive = true
    client.chdir("pub/data/nccf/com/urma/prod/urma2p5.#{args[:date]}")
    files = client.list('*anl_ndfd*')
    filenames = files.map { |file| file.split.last }
    FileUtils.mkpath("../gribdata/#{args[:date]}")
    filenames.each do |filename|
      client.get(filename, "../gribdata/#{args[:date]}/#{args[:date]}.#{filename}")
      puts "File saved: #{args[:date]}.#{filename}"
    end
    puts "All files saved successfully"
  end

  def self.save_single_data_point(lat, long, date)
    DATA_TYPE_SHORTNAME = {
      elevation: 'orog',
      temperature: '2t',
      pressure: 'sp',
      dew_point_temp: '2d',
      cloud_cover: 'tcc'
    }

    files = Dir["../gribdata/#{args[:date]}/*"] #TODO ensure we only grab grib2 files to prevent errors
    hourly_temps = []

    files.each do |file|
      hourly_temps << get_data_point(args[:lat], args[:long], file, DATA_TYPE_SHORTNAME[:temperature])
    end

    WeatherDatum.create(
      max_temperature: K_to_F(hourly_temps.max),
      min_temperature: K_to_F(hourly_temps.min),
      avg_temperature: K_to_F(hourly_temps.inject(:+) / hourly_temps.count),
      latitude: args[:lat],
      longitude: args[:long],
      date: Date.parse(args[:date]))
    puts "data point saved for #{args[:lat]} by #{args[:long]} on #{args[:date]}"
    puts "#{WeatherDatum.last.inspect}"
  end

  private

  def yesterday
    date = Date.today - 1
    "#{date.year}#{date.month}#{date.day}"
  end

  def get_data_point(lat, long, file, data_type)
    data_json = `grib_ls -j -w shortName=#{data_type} -l #{lat},#{long} #{file}`
    data_hash = JSON.parse(data_json)
    data_hash.first['neighbours'].first['value']
  end

  def K_to_F(kelvin_temp)
    (kelvin_temp - 273.15) * 1.8 + 32
  end
end
