require 'rails_helper'
require 'net/ftp'
# require 'fakefs/spec_helpers'

describe Fetcher do
  # include FakeFS::SpecHelpers

  describe '.fetch_day' do
    let(:date) { Date.new(2016,1,5) }
    let(:client_mock) { instance_double("Net::FTP") }

    before do
      allow(client_mock).to receive(:login)
      allow(client_mock).to receive(:passive=)
      allow(client_mock).to receive(:chdir)
      allow(client_mock).to receive(:list).and_return(['a','b','c'])
      allow(client_mock).to receive(:get)

      allow(Net::FTP).to receive(:new).with('ftp.ncep.noaa.gov')
        .and_return(client_mock)
    end

    it 'return file name(s) it saved' do
      expect(Fetcher.fetch_day(date)).to include('.grb2')
    end

    it 'attempts to contact ftp server' do
      expect(Net::FTP).to receive(:new).with('ftp.ncep.noaa.gov')
        .and_return(client_mock)

      Fetcher.fetch_day(date)
    end

    it 'grabs files from the correct folder' do
      simple_date = "#{date.year}#{date.month}#{date.day}"

      expect(client_mock).to receive(:chdir)
        .with("pub/data/nccf/com/urma/prod/urma2p5.#{simple_date}")

      Fetcher.fetch_day(date)
    end

    it 'saves files to the correct folder' do
      path = "../temp_gribdata"
      expect(client_mock).to receive(:get).with(anything,/temp_gribdata/)

      Fetcher.fetch_day(date,path)
    end
  end


end