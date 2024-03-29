require "rails_helper"

RSpec.describe WeatherImporter do
  subject { WeatherImporter }
  let(:date) { "2023-1-1".to_date }

  before do
    allow(Weather).to receive(:create_image)
  end

  describe ".local_dir" do
    let(:dir) { subject::LOCAL_DIR }

    it "should return the local directory to store the weather files" do
      expect(subject.local_dir(date)).to eq("#{dir}/20230101")
    end

    it "should create local directories if they don't exist" do
      allow(Dir).to receive(:exist?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with("#{dir}/20230101").once
      subject.local_dir(date)
    end
  end

  describe ".remote_url" do
    let(:uri) { subject::REMOTE_URL_BASE }

    it "should get the proper UTC date remote directory given a central time date and hour" do
      expect(subject.remote_url(date:, hour: 0)).to eq("#{uri}/rtma2p5.20230101")
      expect(subject.remote_url(date:, hour: 10)).to eq("#{uri}/rtma2p5.20230101")
      expect(subject.remote_url(date:, hour: 23)).to eq("#{uri}/rtma2p5.20230102")
    end
  end

  describe ".remote_file" do
    it "should create the correct filename for each hour given central date and hour" do
      expect(subject.remote_file(date:, hour: 5)).to include(".t11z.")
      expect(subject.remote_file(date:, hour: 12)).to include(".t18z.")
      expect(subject.remote_file(date:, hour: 23)).to include(".t05z.")
    end
  end

  describe ".fetch_day" do
    before do
      allow(subject).to receive(:download_gribs)
      allow(subject).to receive(:persist_day_to_db)
      allow(FileUtils).to receive(:rm_r)
    end

    it "should try to get a file for every hour" do
      expect(subject).to receive(:download_gribs).once
      expect(subject).to receive(:persist_day_to_db).once
      expect(FileUtils).to receive(:rm_r).once
      subject.fetch_day(date)
    end

    it "should create a new WeatherDay to store data" do
      weather_day = instance_double("WeatherDay")
      expect(WeatherDay).to receive(:new).and_return(weather_day)
      expect(weather_day).to receive(:load_from)
      subject.fetch_day(date)
    end

    it "should not delete gribs if KEEP_GRIB" do
      stub_const("ENV", {"KEEP_GRIB" => "true"})
      expect(FileUtils).to_not receive(:rm_r)
      subject.fetch_day(date)
    end
  end

  describe ".download_gribs" do
    # folder changes due to NOAA server storing files in UTC time and we are in CST
    it "should call fetch_grib with correct UTC date" do
      allow(subject).to receive(:fetch_grib).and_return 1
      expect(subject).to receive(:fetch_grib).with(/#{date.to_formatted_s(:number)}/, any_args).exactly(18).times
      expect(subject).to receive(:fetch_grib).with(/#{(date + 1.day).to_formatted_s(:number)}/, any_args).exactly(6).times
      subject.download_gribs(date)
    end
  end

  describe ".persist_day_to_db" do
    let(:weather_day) { WeatherDay.new }

    before do
      # fake mini grid
      allow(LandExtent).to receive(:latitudes).and_return([45.0, 46.0])
      allow(LandExtent).to receive(:longitudes).and_return([-89.0, -88.0])
      allow(weather_day).to receive(:observations_at).and_return(FactoryBot.build_list(:weather_observation, 2))
    end

    it "should load a WeatherDay and save Weather to db" do
      expect { subject.persist_day_to_db(date, weather_day) }.to change { Weather.count }.by(4)
    end
  end
end
