require 'rails_helper'
require 'net/ftp'

RSpec.describe WeatherImporter, type: :model do
  let (:today) { Date.new(2016, 2, 1) }

  describe '.remote_dir' do
    it "should get the proper remote directory given a date" do
      expect(WeatherImporter.remote_dir(today)).to eq "/pub/data/nccf/com/urma/prod/urma2p5.#{today.strftime('%Y%m%d')}"
    end
  end

  describe ".local_dir" do
    let (:today) { Date.current }
    it "should return the local directory to store the weather files" do
      expect(WeatherImporter.local_dir(today)).to eq "/tmp/gribdata/#{today.strftime('%Y%m%d')}"
    end

    it "should create local directories if they don't exist" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with("#{WeatherImporter::LOCAL_BASE_DIR}/gribdata/#{today.strftime('%Y%m%d')}").once
      WeatherImporter.local_dir(today)
    end
  end

  describe "get weather data" do
    let(:ftp_client_mock) { instance_double("Net::FTP") }
    before do
      allow(ftp_client_mock).to receive(:login)
      allow(ftp_client_mock).to receive(:passive=)
      allow(ftp_client_mock).to receive(:get)
      allow(ftp_client_mock).to receive(:chdir)
      allow(Net::FTP).to receive(:new).with('ftp.ncep.noaa.gov').and_return(ftp_client_mock)
    end

    describe '.fetch' do
      it 'get and load files for every day returned by DataImport' do
        unloaded_days = [Date.yesterday, Date.current - 3.days]
        allow(WeatherDataImport).to receive(:days_to_load)
          .and_return(unloaded_days)

        expect(WeatherImporter).to receive(:fetch_day)
          .exactly(unloaded_days.count).times
        expect(WeatherImporter).to receive(:import_weather_data)
          .exactly(unloaded_days.count).times

        WeatherImporter.fetch
      end
    end

    describe "connect to remote FTP server" do
      it "should connect to the NOAA server" do
        expect(Net::FTP).to receive(:new).with('ftp.ncep.noaa.gov').and_return(ftp_client_mock)
        WeatherImporter.connect_to_server
      end

      it "should set the connection to passive" do
        expect(ftp_client_mock).to receive(:passive=).with(true)
        WeatherImporter.connect_to_server
      end

      it "should return the ftp client" do
        expect(WeatherImporter.connect_to_server).to be ftp_client_mock
      end
    end

    describe "get the files from the FTP server" do
      before do
        allow(FileUtils).to receive(:mv)
      end
      it 'should change to the appropriate directories on the remote server' do
        expect(ftp_client_mock).to receive(:chdir).with(WeatherImporter.remote_dir(today + 1.day)).exactly(6).times
        expect(ftp_client_mock).to receive(:chdir).with(WeatherImporter.remote_dir(today)).exactly(18).times
        WeatherImporter.fetch_day(today)
      end

      it 'should try to a file for every hour' do
        expect(ftp_client_mock).to receive(:get).exactly(24).times
        WeatherImporter.fetch_day(today)
      end

      it 'should log an error for file not found' do
        expect(ftp_client_mock).to receive(:get).and_raise(Net::FTPPermError)
        expect(Rails.logger).to receive(:warn)
        WeatherImporter.fetch_day(today)
      end
    end
  end

  describe "load the database for a date" do
    let(:weather_day) { instance_double("WeatherDay") }
    before do
      allow(weather_day).to receive(:load_from).with(WeatherImporter.local_dir(today))
      #allow(weather_day).to receive(:load_database_for).with(today)
      allow(weather_day).to receive(:temperatures_at)
      allow(weather_day).to receive(:dew_points_at)
      allow(weather_day).to receive(:date)
    end

    it "should load a WeatherDay" do
      expect(WeatherDay).to receive(:new).with(today).and_return(weather_day)
      WeatherImporter.import_weather_data(today)
    end
  end

  describe '.K_to_C' do
    it "should return the proper value in Celcius" do
      expect(WeatherImporter.K_to_C(283.0)).to be_within(0.001).of(9.85)
    end
  end

  describe '.dew_point_to_vapor_pressure' do
    it "should return the vapor pressure given a dew point (in Kelvin)" do
      expect(WeatherImporter.dew_point_to_vapor_pressure(303)).to be_within(0.001).of(4.313)
    end
  end

  describe '.weather_average' do
    it "should return the 'average' (sum of low and high/2) of an array" do
      expect(WeatherImporter.weather_average([0.0, 1.0, 5.0, 10.0])).to eq 5.0
    end
    it "should return 0 for an empty array" do
      expect(WeatherImporter.weather_average([])).to eq 0.0
    end
  end

  describe 'central time' do
    it 'should return a time for a given date and hour in Central Time' do
      expect(WeatherImporter.central_time(today, 0).zone).to eq 'CST'
    end

    it 'should set the hour as given' do
      expect(WeatherImporter.central_time(today, 0).hour).to eq 0
    end

    it 'should set the date as given' do
      expect(WeatherImporter.central_time(today, 0).to_date).to eq today
    end
  end

end
