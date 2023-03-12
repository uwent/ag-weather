require "rails_helper"

class DummyClass < DataImporter
  extend GribMethods

  def self.earliest_date
    1.week.ago.to_date
  end

  def self.latest_date
    Date.today
  end

  def self.fetch_day(date, force:)
  end
end

RSpec.describe GribMethods, type: :module do
  let(:dc) { DummyClass }
  let(:date) { Date.new(2022, 1, 10) }

  describe ".grib_dir" do
    it { expect(dc.grib_dir).to eq "/tmp/gribdata" }
  end

  describe ".keep_grib" do
    it "defaults to false" do
      expect(dc.keep_grib).to eq false
    end

    it "reads the KEEP_GRIB environment variable" do
      stub_const("ENV", {"KEEP_GRIB" => "true"})
      expect(dc.keep_grib).to eq true
    end
  end

  describe ".central_time" do
    it "should return a time for a given date and hour in Central Time" do
      expect(dc.central_time(date, 0).zone).to eq("CST")
    end

    it "should set the hour as given" do
      expect(dc.central_time(date, 0).hour).to eq(0)
    end

    it "should set the date as given" do
      expect(dc.central_time(date, 0).to_date).to eq(date)
    end
  end

  describe ".fetch" do
    context "when no missing dates" do
      it "doesn't call fetch_day" do
        allow(dc).to receive(:missing_dates).and_return([])
        expect(dc).to receive(:fetch_day).exactly(0).times
      end
    end

    context "when missing dates" do
      let(:all_dates) { (dc.earliest_date..dc.latest_date).to_a }
      let(:missing_dates) { all_dates.last(3) }
      let(:data_mock) { double("data") }
      let(:import_mock) { double("import") }

      before do
        allow(dc).to receive(:data_class).and_return(data_mock)
        allow(dc).to receive(:import).and_return(import_mock)
        allow(data_mock).to receive(:find_by).and_return(false)
      end

      it "calls fetch_day for each missing day" do
        allow(dc).to receive(:missing_dates).and_return(missing_dates)
        missing_dates.each do |date|
          expect(dc).to receive(:fetch_day).with(date, any_args).ordered.once
        end
        dc.fetch
      end

      it "calls fetch_day for each day when all_dates: true" do
        all_dates.each do |date|
          expect(dc).to receive(:fetch_day).with(date, any_args).ordered.once
        end
        dc.fetch(all_dates: true)
      end

      it "creates a successful import if data exists" do
        allow(data_mock).to receive(:find_by).and_return(true)
        all_dates.each do |date|
          expect(import_mock).to receive(:succeed).with(date).ordered.once
        end
        dc.fetch(all_dates: true)
      end

      it "calls fetch_day if exists but overwrite: true" do
        allow(data_mock).to receive(:find_by).and_return(true)
        all_dates.each do |date|
          expect(dc).to receive(:fetch_day).with(date, anything).ordered.once
        end
        dc.fetch(all_dates: true, overwrite: true)
      end

      it "creates a fail record if fetch_day fails" do
        allow(dc).to receive(:fetch_day).and_raise StandardError
        all_dates.each do |date|
          expect(import_mock).to receive(:fail).with(date, kind_of(String)).ordered.once
        end
        dc.fetch(all_dates: true)
      end
    end
  end

  describe ".download_gribs" do
    before do
      allow(dc).to receive(:local_dir).and_return("dir")
      allow(dc).to receive(:remote_url).and_return("url")
      allow(dc).to receive(:remote_file).and_return("file")
    end

    it "should raise error if it fails to download gribs" do
      allow(dc).to receive(:fetch_grib).and_return 0
      expect { dc.download_gribs(date) }.to raise_error(StandardError)
    end

    it "should not raise error if it fails to download all the gribs but force: true" do
      allow(dc).to receive(:fetch_grib).and_return(0, 1)
      expect { dc.download_gribs(date, force: true) }.to_not raise_error
    end
  end

  describe ".fetch_grib" do
    let(:url) { "https://example.com/foo.grib2" }
    let(:file) { "local.file" }

    it "should return 1 if file already exists" do
      allow(File).to receive(:exists?).and_return(true)
      allow(dc).to receive(:download)

      expect(dc.fetch_grib("url", "file")).to eq 1
    end

    it "should try to download the url if the local file does not exist" do
      allow(File).to receive(:exists?).and_return(false)
      allow(dc).to receive(:download)

      expect(dc).to receive(:download).with(url, file)
      expect(dc.fetch_grib(url, file)).to eq 1
    end

    it "should return 0 if the download fails" do
      allow(File).to receive(:exists?).and_return(false)
      allow(dc).to receive(:download).and_raise(StandardError.new)

      expect(dc.fetch_grib(url, file)).to eq 0
    end
  end

  describe ".download" do
    it "downloads a file from a URL" do
      true
    end
  end
end
