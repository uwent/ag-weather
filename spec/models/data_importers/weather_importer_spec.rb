require "rails_helper"

RSpec.describe WeatherImporter do
  subject { WeatherImporter }
  let(:date) { "2023-1-1".to_date }
  let(:datestring) { date.to_formatted_s(:number) }

  before do
    allow(WeatherDatum).to receive(:create_image)
  end

  describe ".local_dir" do
    let(:dir) { subject::LOCAL_DIR }

    it "should return the local directory to store the weather files" do
      expect(subject.local_dir(date)).to eq("#{dir}/#{datestring}")
    end

    it "should create local directories if they don't exist" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with("#{dir}/#{datestring}").once
      subject.local_dir(date)
    end
  end

  describe ".remote_url" do
    let(:uri) { subject::REMOTE_URL_BASE }

    it "should get the proper remote directory given a date" do
      expect(subject.remote_url(date)).to eq("#{uri}/rtma2p5.#{datestring}")
    end
  end

  describe ".remote_file" do
    it "should create the correct filename for each hour" do
      expect(subject.remote_file(hour: 5)).to include(".t05z.")
      expect(subject.remote_file(hour: 12)).to include(".t12z.")
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

    it "should try to create an image" do
      expect(WeatherDatum).to receive(:create_image).with(date:).once
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

  describe ".persist_day_to_db", skip: true do
    before(:each) do
      weather_day = WeatherDay.new(date:)
      allow(weather_day).to receive(:observations_at).and_return(FactoryBot.build_list(:weather_observation, 2))
    end

    it "should load a WeatherDay" do
      expect(WeatherDay).to receive(:new).with(date).and_return(weather_day)
      subject.persist_day_to_db(weather_day)
    end

    # it "should save the weather data" do
    #   allow(weather_day).to receive(:obs_at).and_return([WeatherObservation.new(21, 18)])
    #   allow(weather_day).to receive(:date).and_return(Date.yesterday)
    #   expect { subject.persist_day_to_db(weather_day) }.to change { WeatherDatum.count }.by(LandExtent.num_points)
    # end
  end

  describe ".count_rh_over" do
    it "counts all if temperature is same as dewpoint (rel. humidity is 100)" do
      obs = FactoryBot.build_list(:weather_observation, 20)
      expect(subject.count_rh_over(obs, 90.0)).to eq 20
    end

    it "only counts those above cutoff" do
      obs = FactoryBot.build_list(:weather_observation, 10, temperature: 300, dew_point: 300) # RH 100%
      obs += FactoryBot.build_list(:weather_observation, 10, temperature: 300, dew_point: 298) # RH < 90
      expect(subject.count_rh_over(obs, 90.0)).to eq 10
    end

    it "returns zero for an empty list" do
      expect(subject.count_rh_over([], 90.0)).to eq 0
    end
  end

  describe ".avg_temp_rh_over" do
    it "returns the average of those over rh cutoff" do
      obs = FactoryBot.build_list(:weather_observation, 10, temperature: 300, dew_point: 300) # RH 100%
      obs += FactoryBot.build_list(:weather_observation, 10, temperature: 275, dew_point: 250) # RH < 90
      expect(subject.avg_temp_rh_over(obs, 90.0)).to eq UnitConverter.k_to_c(300)
    end

    it "returns nil when none over rh cutoff" do
      obs = FactoryBot.build_list(:weather_observation, 10, temperature: 275, dew_point: 250) # RH < 90
      expect(subject.avg_temp_rh_over(obs, 90.0)).to eq nil
    end
  end

  describe ".simple_avg" do
    it "should return the simple average (sum of low and high/2) of an array" do
      expect(subject.simple_avg([10.0, 0.0, 1.0, 5.0, 10.0])).to eq 5.0
    end

    it "should return 0 for an empty array" do
      expect(subject.simple_avg([])).to eq 0.0
    end
  end

  describe ".true_avg" do
    it "should return the true average (sum/count) of an array" do
      expect(subject.true_avg([10.0, 0.0, 1.0, 5.0, 10.0])).to eq 5.2
    end

    it "should return 0 for an empty array" do
      expect(subject.true_avg([])).to eq 0.0
    end
  end
end
