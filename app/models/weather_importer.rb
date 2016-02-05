class WeatherImporter
  REMOTE_BASE_DIR = "pub/data/nccf/com/urma/prod"
  LOCAL_BASE_DIR = "/tmp"

  def self.remote_dir(date)
    "#{REMOTE_BASE_DIR}/urma2p5.#{date.strftime('%Y%m%d')}"
  end

  def self.local_dir(date)
    gribdir = "#{LOCAL_BASE_DIR}/gribdata"
    FileUtils.mkpath(gribdir) unless Dir.exists?(gribdir)
    savedir = "#{gribdir}/#{date.strftime('%Y%m%d')}"
    FileUtils.mkpath(savedir) unless Dir.exists?(savedir)
    savedir
  end

  def self.remote_file_name(hour)
    sprintf("urma2p5.t%02dz.2dvaranl_ndfd.grb2", hour)
  end

  def self.connect_to_server
    client = Net::FTP.new('ftp.ncep.noaa.gov')
    client.login
    client.passive = true
    client
  end

  def self.fetch_files(date)
    client = connect_to_server
    client.chdir(remote_dir(date))
    0.upto(23) do |hour|
      filename = remote_file_name(hour)
      client.get(filename, "#{local_dir(date)}/#{date}.#{filename}" )
    end
  end
end
