require 'rails_helper'
require 'net/ftp'

RSpec.describe WeatherImporter, type: :model do
  let (:today) { Date.current}

  describe '.remote_dir' do
    it "should get the proper remote directory given a date" do
      expect(WeatherImporter.remote_dir(Date.current)).to eql "pub/data/nccf/com/urma/prod/urma2p5.#{today.strftime('%Y%m%d')}"
    end
  end

  describe ".local_dir" do
    let (:today) { Date.current }
    it "should return the local directory to store the weather files" do
      expect(WeatherImporter.local_dir(today)).to eql "/tmp/gribdata/#{today.strftime('%Y%m%d')}"
    end

    it "should create local directories if they don't exist" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect(FileUtils).to receive(:mkpath).with("#{WeatherImporter::LOCAL_BASE_DIR}/gribdata").once
      expect(FileUtils).to receive(:mkpath).with("#{WeatherImporter::LOCAL_BASE_DIR}/gribdata/#{today.strftime('%Y%m%d')}").once
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
      it 'should change to the appropriate directory on the remote server' do
        expect(ftp_client_mock).to receive(:chdir)
        WeatherImporter.fetch_files(today)
      end

      it 'should try to a file for every hour' do
        expect(ftp_client_mock).to receive(:get).exactly(24).times
        WeatherImporter.fetch_files(today)
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
      WeatherImporter.load_database_for(today)
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
      expect(WeatherImporter.weather_average([0.0, 1.0, 5.0, 10.0])).to eql 5.0
    end
    it "should return 0 for an empty array" do
      expect(WeatherImporter.weather_average([])).to eql 0.0
    end
  end

end
