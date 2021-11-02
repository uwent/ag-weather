require 'rails_helper'
require 'net/ftp'

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

  describe ".fetch_day" do
    let(:client) { instance_double("Net::FTP") }

    before(:each) do
      allow(client).to receive(:login)
      allow(client).to receive(:get)
      allow(client).to receive(:chdir)
      allow(client).to receive(:close)
      allow(Net::FTP).to receive(:new).with(PrecipImporter::REMOTE_SERVER).and_return(client)
    end

    describe ".connect_to_server" do
      it "should connect to the ftp server" do
        expect(Net::FTP).to receive(:new).with(PrecipImporter::REMOTE_SERVER).and_return(client)
        PrecipImporter.connect_to_server
      end

      it "should return the ftp client" do
        expect(PrecipImporter.connect_to_server).to be client
      end
    end

    describe ".local_file" do
      it "should create the local directory if it doesn't exist" do
        expect(FileUtils).to receive(:mkdir_p).with("#{PrecipImporter::LOCAL_DIR}").once
        PrecipImporter.local_file(date)
      end

      it "should specify local filename" do
        expect(PrecipImporter.local_file(date)).to eq("#{PrecipImporter::LOCAL_DIR}/#{date.to_s(:number)}.grb2")
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

    describe "get precip data" do
      it "should connect to the server" do
        expect(PrecipImporter).to receive(:connect_to_server).exactly(1).times
        PrecipImporter.fetch_day(date)
      end

      it "should change to the appropriate directory on the remote server" do
        expect(client).to receive(:chdir).with(PrecipImporter.remote_dir(date)).exactly(1).times
        PrecipImporter.fetch_day(date)
      end

      it "should try to get a file" do
        expect(client).to receive(:get).exactly(1).times
        PrecipImporter.fetch_day(date)
      end
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
