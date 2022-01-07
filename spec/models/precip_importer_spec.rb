require "rails_helper"

RSpec.describe PrecipImporter, type: :model do
  let(:date) { Date.current }

  describe ".fetch" do
    it "should fetch precips for each day required" do
      unloaded_days = [Date.current - 3.days, Date.current - 1.day]
      allow(PrecipDataImport).to receive(:days_to_load).and_return(unloaded_days)
      expect(PrecipImporter).to receive(:fetch_day).exactly(unloaded_days.size).times
      PrecipImporter.fetch
    end
  end

  describe ".local_file" do
    it "should create the local directory if it doesn't exist" do
      expect(FileUtils).to receive(:mkdir_p).with(PrecipImporter::LOCAL_DIR.to_s).once
      PrecipImporter.local_file(date)
    end

    it "should specify local filename" do
      expect(PrecipImporter.local_file(date)).to eq("#{PrecipImporter::LOCAL_DIR}/#{date.to_s(:number)}.grb2")
    end

    it "should create the file directory if it doesn't exist" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with(PrecipImporter::LOCAL_DIR).once
      PrecipImporter.local_file(date)
    end
  end

  describe ".remote_dir" do
    it "should specify the correct remote directory" do
      dir = PrecipImporter::REMOTE_DIR_BASE + "/pcpanl.#{date.to_s(:number)}"
      expect(PrecipImporter.remote_dir(date)).to eq(dir)
    end
  end

  describe ".remote_file" do
    it "should create the correct remote filename" do
      file = "st4_conus.#{date.to_s(:number)}12.24h.grb2"
      expect(PrecipImporter.remote_file(date)).to eq(file)
    end
  end

  describe ".fetch_day" do
    it "should try to download the grib file" do
      allow(PrecipImporter).to receive(:download).and_return("file")
      expect(PrecipImporter).to receive(:download).with(/#{date.to_s(:number)}/, any_args).exactly(1).times
      PrecipImporter.fetch_day(date)
    end
  end

  describe ".import_precip_data" do
    let(:precip_mock) { LandGrid.new }

    before(:each) do
      allow(PrecipImporter).to receive(:load_from).and_return(precip_mock)
    end

    it "should load a grib file" do
      expect(PrecipImporter).to receive(:load_from).exactly(1).times
      PrecipImporter.import_precip_data(date)
    end

    it "should write precip data to db" do
      expect { PrecipImporter.write_to_db(precip_mock, date) }.to change { Precip.count }.by(LandExtent.num_points)
    end
  end
end
