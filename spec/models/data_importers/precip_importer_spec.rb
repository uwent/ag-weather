require "rails_helper"

RSpec.describe PrecipImporter do
  subject { PrecipImporter }
  let(:data_class) { Precip }
  let(:import_class) { PrecipDataImport }
  let(:date) { Date.current }
  let(:datestring) { date.to_formatted_s(:number) }
  let(:mock_data) {
    {
      [45.0, -89.0] => 1.0,
      [45.0, -90.0] => 2.0,
      [46.0, -89.0] => 3.0,
      [46.0, -90.0] => 4.0
    }
  }

  before do
    allow(data_class).to receive(:create_image)
  end

  describe ".data_class" do
    it { expect(subject.data_class).to eq data_class }
  end

  describe ".import" do
    it { expect(subject.import).to eq import_class }
  end

  describe ".local_dir" do
    it "should create the file directory if it doesn't exist" do
      local_dir = "#{subject::LOCAL_DIR}/#{datestring}"
      allow(Dir).to receive(:exist?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with(local_dir).once
      subject.local_dir(date)
    end
  end

  describe ".remote_url" do
    it "should specify the correct remote directory" do
      url = subject::REMOTE_URL_BASE + "/pcpanl.#{datestring}"
      expect(subject.remote_url(date:, hour: nil)).to eq url
    end
  end

  describe ".remote_file" do
    it "should create the correct remote filename" do
      expect(subject.remote_file(date:, hour: 1)).to eq "st4_conus.#{datestring}01.01h.grb2"
      expect(subject.remote_file(date:, hour: 12)).to eq "st4_conus.#{datestring}12.01h.grb2"
      expect(subject.remote_file(date:, hour: 23)).to eq "st4_conus.#{datestring}23.01h.grb2"
    end
  end

  describe ".fetch_day" do
    before do
      allow(subject).to receive(:download_gribs)
      allow(subject).to receive(:load_from).and_return(mock_data)
    end

    it "should try to download the grib files" do
      expect(subject).to receive(:download_gribs).with(date, any_args).once
      subject.fetch_day(date)
    end
  end

  describe ".download_gribs" do
    it "should call fetch_grib with correct file timestamp" do
      allow(subject).to receive(:fetch_grib).and_return 1
      0.upto(23) do |hour|
        expect(subject).to receive(:fetch_grib).with(/#{date.to_formatted_s(:number)}#{hour.to_s.rjust(2, "0")}/, any_args).once
      end
      subject.download_gribs(date)
    end
  end

  describe ".load_from" do
    before do
      allow(FileUtils).to receive(:rm_r)
    end

    it "should try to load all grib files from a directory" do
      allow(Dir).to receive(:[]).and_return(["file1", "file2"])
      expect(subject).to receive(:load_grib).exactly(2).times.and_return({})
      subject.load_from("dir")
    end

    context "with valid data" do
      before do
        allow(Dir).to receive(:[]).and_return(["file1", "file2"])
        allow(subject).to receive(:load_grib).and_return(mock_data)
      end

      it "should return a hash" do
        expect(subject.load_from("dir")).to be_an Hash
      end

      it "should have a key for each lat/long point" do
        expect(subject.load_from("dir").keys.size).to eq(LandExtent.num_points)
      end

      it "should add up all hourly values at each point" do
        hash = subject.load_from("dir")
        expect(hash[[45.0, -89.0]]).to eq 2.0 # two points @ 1.0 each
        expect(hash[[46.0, -90.0]]).to eq 8.0 # two points @ 4.0 each
      end

      it "should default to 0.0 for missing points within extent" do
        hash = subject.load_from("dir")
        expect(hash[[44.0, -89.0]]).to eq 0.0
      end

      it "should return nil for points outside extent" do
        hash = subject.load_from("dir")
        expect(hash[[1.0, 2.0]]).to be_nil
      end
    end

    it "should delete the grib dir when done" do
      allow(Dir).to receive(:[]).and_return([])
      expect(FileUtils).to receive(:rm_r).with("dir")
      subject.load_from("dir")
    end

    it "should keep the grib dir if KEEP_GRIB = true" do
      stub_const("ENV", {"KEEP_GRIB" => "true"})
      allow(Dir).to receive(:[]).and_return([])
      expect(FileUtils).to_not receive(:rm_r)
      subject.load_from("dir")
    end
  end

  # describe ".import_precip_data" do
  #   let(:precip_mock) { LandGrid.new }

  #   before(:each) do
  #     allow(PrecipImporter).to receive(:load_from).and_return(precip_mock)
  #   end

  #   it "should load a grib file" do
  #     expect(PrecipImporter).to receive(:load_from).exactly(1).times
  #     PrecipImporter.import_precip_data(date)
  #   end

  #   it "should write precip data to db" do
  #     expect { PrecipImporter.write_to_db(precip_mock, date) }.to change { Precip.count }.by(LandExtent.num_points)
  #   end
  # end
end
