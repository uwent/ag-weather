require "rails_helper"

RSpec.describe WeatherImporter, type: :model do
  let(:date) { Date.new(2022, 1, 10) }

  describe ".remote_url" do
    it "should get the proper remote directory given a date" do
      expect(WeatherImporter.remote_url(date)).to eq("#{WeatherImporter::REMOTE_URL_BASE}/rtma2p5.#{date.strftime("%Y%m%d")}")
    end
  end

  describe ".local_dir" do
    it "should return the local directory to store the weather files" do
      expect(WeatherImporter.local_dir(date)).to eq("#{WeatherImporter::LOCAL_DIR}/#{date.strftime("%Y%m%d")}")
    end

    it "should create local directories if they don't exist" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with("#{WeatherImporter::LOCAL_DIR}/#{date.strftime("%Y%m%d")}").once
      WeatherImporter.local_dir(date)
    end
  end

  describe ".fetch" do
    it "should get and load files for every day returned by DataImport" do
      unloaded_days = [date, date - 3.days]
      allow(WeatherDataImport).to receive(:days_to_load).and_return(unloaded_days)
      expect(WeatherImporter).to receive(:fetch_day).exactly(unloaded_days.count).times
      WeatherImporter.fetch
    end
  end

  describe ".fetch_day" do
    before(:each) do
      allow(FileUtils).to receive(:mv)
      allow(WeatherImporter).to receive(:download).and_return("file")
      allow(WeatherImporter).to receive(:import_weather_data).and_return("data")
    end

    it "should try to get a file for every hour" do
      expect(WeatherImporter).to receive(:download).exactly(24).times
      WeatherImporter.fetch_day(date)
    end

    # folder changes due to NOAA server storing files in UTC time and we are in CST
    it "should set the appropriate base URL on the remote server" do
      expect(WeatherImporter).to receive(:download).with(/#{date.to_formatted_s(:number)}/, any_args).exactly(18).times
      expect(WeatherImporter).to receive(:download).with(/#{(date + 1.day).to_formatted_s(:number)}/, any_args).exactly(6).times
      WeatherImporter.fetch_day(date)
    end
  end

  describe "load the database for a date" do
    let(:weather_day) { instance_double("WeatherDay") }

    before(:each) do
      allow(weather_day).to receive(:load_from).with(WeatherImporter.local_dir(date))
      allow(weather_day).to receive(:temperatures_at)
      allow(weather_day).to receive(:observations_at)
      allow(weather_day).to receive(:temperatures_at)
      allow(weather_day).to receive(:dew_points_at)
      allow(weather_day).to receive(:date)
    end

    it "should load a WeatherDay" do
      expect(WeatherDay).to receive(:new).with(date).and_return(weather_day)
      WeatherImporter.import_weather_data(date)
    end
  end

  describe "persist a day to the database" do
    let(:weather_day) { instance_double("WeatherDay") }

    it "should save the weather data" do
      allow(weather_day).to receive(:observations_at).and_return([WeatherObservation.new(21, 18)])
      allow(weather_day).to receive(:date).and_return(Date.yesterday)
      expect { WeatherImporter.persist_day_to_db(weather_day) }.to change { WeatherDatum.count }.by(LandExtent.num_points)
    end
  end

  describe ".dew_point_to_vapor_pressure" do
    it "should return the vapor pressure given a dew point (in Celsius)" do
      expect(WeatherImporter.dew_point_to_vapor_pressure(29.85)).to be_within(0.001).of(4.313)
    end
  end

  describe ".relative_humidity_over" do
    it "counts all if temperature is same as dewpoint (rel. humidity is 100) " do
      observations = FactoryBot.build_list :weather_observation, 20
      expect(WeatherImporter.relative_humidity_over(observations, 85.0)).to eq(20)
    end

    it "only counts the ones where temp is same as dewpoint" do
      observations = FactoryBot.build_list :weather_observation, 10
      observations += FactoryBot.build_list(:weather_observation, 10, dew_point: 273.15)
      expect(WeatherImporter.relative_humidity_over(observations, 85.0)).to eq(10)
    end

    it "zero for an empty list" do
      expect(WeatherImporter.relative_humidity_over([], 85.0)).to eq(0)
    end

    it "counts those on edge of 85.0" do
      observation = FactoryBot.build(:weather_observation, dew_point: 287.60954)
      expect(WeatherImporter.relative_humidity_over([observation], 85.0)).to eq(1)
    end

    it "doesn't count those on edge of 85.0" do
      observation = FactoryBot.build(:weather_observation, dew_point: 287.60952)
      expect(WeatherImporter.relative_humidity_over([observation], 85.0)).to eq(0)
    end
  end

  describe ".weather_average" do
    it "should return the 'average' (sum of low and high/2) of an array" do
      expect(WeatherImporter.weather_average([0.0, 1.0, 5.0, 10.0])).to eq(5.0)
    end

    it "should return 0 for an empty array" do
      expect(WeatherImporter.weather_average([])).to eq(0.0)
    end
  end
end