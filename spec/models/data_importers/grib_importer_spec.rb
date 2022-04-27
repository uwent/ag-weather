require "rails_helper"

RSpec.describe GribImporter, type: :model do
  let(:date) { Date.new(2022, 1, 10) }

  describe ".central_time" do
    it "should return a time for a given date and hour in Central Time" do
      expect(GribImporter.central_time(date, 0).zone).to eq("CST")
    end

    it "should set the hour as given" do
      expect(GribImporter.central_time(date, 0).hour).to eq(0)
    end

    it "should set the date as given" do
      expect(GribImporter.central_time(date, 0).to_date).to eq(date)
    end
  end

  describe ".fetch_grib" do
    let(:url) { "https://example.com/foo.grib2" }
    let(:file) { "local.file" }

    it "should return 1 if file already exists" do
      allow(File).to receive(:exists?).and_return(true)
      allow(GribImporter).to receive(:download)

      expect(GribImporter.fetch_grib("url", "file")).to eq 1
    end

    it "should try to download the url if the local file does not exist" do
      allow(File).to receive(:exists?).and_return(false)
      allow(GribImporter).to receive(:download)

      expect(GribImporter).to receive(:download).with(url, file)
      expect(GribImporter.fetch_grib(url, file)).to eq 1
    end

    it "should return 0 if the download fails" do
      allow(File).to receive(:exists?).and_return(false)
      allow(GribImporter).to receive(:download).and_raise(StandardError.new)

      expect(GribImporter.fetch_grib(url, file)).to eq 0
    end
  end
end
