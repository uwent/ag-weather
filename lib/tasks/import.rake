require 'net/ftp'

namespace :import do
  desc 'Load days worth of files from NWS FTP server'
  task :files, [:date] => :environment do |t, args|
    args.with_defaults(date: yesterday)

    Importer.save_files(args[:date])
  end

  desc 'Read files and load relevant data into DBs'
  task :single_point, [:lat, :long, :date] => :environment do |t, args|

    Importer.save_single_data_point(args[:lat], args[:long], args[:date])
  end
end

def yesterday
  date = Date.today - 1
  "#{date.year}#{date.month}#{date.day}"
end
