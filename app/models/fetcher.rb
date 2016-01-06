class Fetcher

  def self.fetch_day(date, folder_path="../gribdata")
    simple_date = "#{date.year}#{date.month}#{date.day}"

    contact_server
    filenames = find_remote_files_for(simple_date)
    save_files_locally(simple_date, filenames, folder_path)

    "some.date.grb2"
  end

  def self.contact_server
    @@client = Net::FTP.new('ftp.ncep.noaa.gov')
    @@client.login
    @@client.passive = true
  end

  def self.find_remote_files_for(date)
    @@client.chdir("pub/data/nccf/com/urma/prod/urma2p5.#{date}")
    files = @@client.list('*anl_ndfd*')
    files.map { |file| file.split.last }
  end

  def self.save_files_locally(date, filenames, folder_path)
    FileUtils.mkpath("#{folder_path}/#{date}")
    filenames.each do |filename|
      @@client.get(filename, "#{folder_path}/#{date}/#{date}.#{filename}")
      puts "File saved: #{date}.#{filename}"
    end
    puts "All files saved successfully"
  end
end