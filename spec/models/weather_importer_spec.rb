require 'rails_helper'
require 'net/ftp'

RSpec.describe WeatherImporter, type: :model do
  let(:today) { Date.new(2016, 2, 1) }

  describe '.remote_dir' do
    it "should get the proper remote directory given a date" do
      expect(WeatherImporter.remote_dir(today)).to eq "#{WeatherImporter::REMOTE_BASE_DIR}/urma2p5.#{today.strftime('%Y%m%d')}"
    end
  end

  describe ".local_dir" do
    let(:today) { Date.current }
    it "should return the local directory to store the weather files" do
      expect(WeatherImporter.local_dir(today)).to eq "#{WeatherImporter::LOCAL_BASE_DIR}/gribdata/#{today.strftime('%Y%m%d')}"
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
      allow(ftp_client_mock).to receive(:get)
      allow(ftp_client_mock).to receive(:chdir)
      allow(Net::FTP).to receive(:new).with(WeatherImporter::REMOTE_SERVER).and_return(ftp_client_mock)
    end

    describe '.fetch' do
      it 'get and load files for every day returned by DataImport' do
        unloaded_days = [Date.yesterday, Date.current - 3.days]
        allow(WeatherDataImport).to receive(:days_to_load)
          .and_return(unloaded_days)

        expect(WeatherImporter).to receive(:fetch_day)
          .exactly(unloaded_days.count).times

        ## import_weather_data is now called by fetch_day rather than fetch after all files fetched
        # expect(WeatherImporter).to receive(:import_weather_data)
        #   .exactly(unloaded_days.count).times

        WeatherImporter.fetch
      end
    end

    describe "connect to remote FTP server" do
      it "should connect to the NOAA server" do
        expect(Net::FTP).to receive(:new).with(WeatherImporter::REMOTE_SERVER).and_return(ftp_client_mock)
        WeatherImporter.connect_to_server
      end

      # # connection is passive by default
      # it "should set the connection to passive" do
      #   expect(ftp_client_mock).to receive(:passive=).with(true)
      #   WeatherImporter.connect_to_server
      # end

      it "should return the ftp client" do
        expect(WeatherImporter.connect_to_server).to be ftp_client_mock
      end
    end

    describe "get the files from the FTP server" do
      before do
        allow(FileUtils).to receive(:mv)
      end

      # changes due to server storing files in UTC time and we are in CST
      it 'should change to the appropriate directories on the remote server' do
        expect(ftp_client_mock).to receive(:chdir).with(WeatherImporter.remote_dir(today)).exactly(18).times
        expect(ftp_client_mock).to receive(:chdir).with(WeatherImporter.remote_dir(today + 1.day)).exactly(6).times
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
      allow(weather_day).to receive(:observations_at)
      allow(weather_day).to receive(:temperatures_at)
      allow(weather_day).to receive(:dew_points_at)
      allow(weather_day).to receive(:date)
    end

    it "should load a WeatherDay" do
      expect(WeatherDay).to receive(:new).with(today).and_return(weather_day)
      WeatherImporter.import_weather_data(today)
    end
  end

  describe "persist a day to the database"  do
    let(:weather_day) { instance_double("WeatherDay") }

    it "should save the weather data" do
      allow(weather_day).to receive(:observations_at).and_return([WeatherObservation.new(21, 18)])
      allow(weather_day).to receive(:date).and_return(Date.yesterday)
      expect { WeatherImporter.persist_day_to_db(weather_day) }.to change {WeatherDatum.count}.by(3328)
    end
  end

  describe '.dew_point_to_vapor_pressure' do
    it "should return the vapor pressure given a dew point (in Celcius)" do
      expect(WeatherImporter.dew_point_to_vapor_pressure(29.85)).to be_within(0.001).of(4.313)
    end
  end

  describe '.relative_humidity_over' do
    it "counts all if temperature is same as dewpoint (rel. humidity is 100) " do
      observations = FactoryBot.build_list :weather_observation, 20
      expect(WeatherImporter.relative_humidity_over(observations, 85.0)).to eq 20
    end

    it "only counts the ones where temp is same as dewpoint" do
      observations = FactoryBot.build_list :weather_observation, 10
      observations += FactoryBot.build_list(:weather_observation, 10, dew_point: 273.15)
      expect(WeatherImporter.relative_humidity_over(observations, 85.0)).to eq 10
    end

    it "zero for an empty list" do
      expect(WeatherImporter.relative_humidity_over([], 85.0)).to eq 0
    end

    it 'counts those on edge of 85.0' do
      observation = FactoryBot.build(:weather_observation, dew_point: 287.60953)
      expect(WeatherImporter.relative_humidity_over([observation], 85.0)).to eq 1
    end

    it "doesn't count those on edge of 85.0" do
      observation = FactoryBot.build(:weather_observation, dew_point: 287.60953)
      expect(WeatherImporter.relative_humidity_over([observation], 85.0)).to eq 1
    end

    it "doesn't count those on edge of 85.0" do
      observation = FactoryBot.build(:weather_observation, dew_point: 287.60952)
      expect(WeatherImporter.relative_humidity_over([observation], 85.0)).to eq 0
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
