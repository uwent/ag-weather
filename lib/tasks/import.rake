require 'net/ftp'

namespace :import do
  desc 'Load days worth of files from NWS FTP server'
  task :files, [:date] => :environment do |t, args|
    args.with_defaults(date: yesterday)

    Importer.save_files(date)
  end

  desc 'Read files and load relevant data into DBs'
  task :single_point, [:lat, :long, :date] => :environment do |t, args|

    Importer.save_single_data_point(lat, long, date)
  end
end


