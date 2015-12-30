class Importer

  DATA_TYPE_SHORTNAME = {
    elevation: 'orog',
    temperature: '2t',
    pressure: 'sp',
    dew_point_temp: '2d',
    cloud_cover: 'tcc'
  }

  def self.save_files(date)
    contact_server
    filenames = find_remote_files_for(date)
    save_files_locally(date, filenames)
  end

  def self.save_single_data_point(lat, long, date)
    @@lat = lat
    @@long = long
    @@date = date

    data_types = [:temperature]   #Eventually get this from user?

    files = find_saved_files
    hourly_data = get_data_from_files(files, data_types)
    save_data_to_database(hourly_data)
  end

  def self.find_remote_files_for(date)
    @@client.chdir("pub/data/nccf/com/urma/prod/urma2p5.#{date}")
    files = @@client.list('*anl_ndfd*')
    files.map { |file| file.split.last }
  end

  private

  def self.find_saved_files
    Dir["../gribdata/#{@@date}/*"] #TODO ensure we only grab grib2 files to prevent errors
  end

  def self.get_data_from_files(files, data_types)
    hourly_data = Hash.new { |hash, key| hash[key] = [] }

    files.each do |file|
      get_data_point(file, data_types, hourly_data)
    end

    hourly_data
  end

  def self.get_data_point(file, data_types, hourly_data)
    types_for_grib = data_types.map { |dt| DATA_TYPE_SHORTNAME[dt] }.join("/")

    data_json = `grib_ls -j -w shortName=#{types_for_grib} -l #{@@lat},#{@@long} #{file}`
    data_hash = JSON.parse(data_json)

    data_hash.each do |data_block|
      type_shortname = data_block['keys']['shortName']
      data_type = DATA_TYPE_SHORTNAME.key(type_shortname)
      value = data_block['neighbours'].first['value']

      hourly_data[data_type] << value
    end
  end

  def self.save_data_to_database(hourly_data)
    WeatherDatum.create(
      max_temperature: K_to_C(hourly_data[:temperature].max),
      min_temperature: K_to_C(hourly_data[:temperature].min),
      avg_temperature: K_to_C(hourly_data[:temperature].inject(:+) / hourly_data[:temperature].count),
      latitude: @@lat,
      longitude: @@long,
      date: Date.parse(@@date))
    puts "data point saved for #{@@lat} by #{@@long} on #{@@date}"
    puts "#{WeatherDatum.last.inspect}"
  end

  def self.contact_server
    @@client = Net::FTP.new('ftp.ncep.noaa.gov')
    @@client.login
    @@client.passive = true
  end

  def self.save_files_locally(date, filenames)
    FileUtils.mkpath("../gribdata/#{date}")
    filenames.each do |filename|
      @@client.get(filename, "../gribdata/#{date}/#{date}.#{filename}")
      puts "File saved: #{date}.#{filename}"
    end
    puts "All files saved successfully"
  end

  def self.K_to_C(kelvin_temp)
    kelvin_temp - 273.15
  end
end
