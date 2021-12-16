require "rails_helper"

RSpec.describe Precip, type: :model do
  describe "construct land grid grid with precip values for given date" do
    let(:date) { Date.current }

    it "should construct a land grid of precip values" do
      expect(Precip.land_grid_for_date(date)).to be_kind_of(LandGrid)
    end

    it "should have precips stored" do
      1.upto(5) do
        lat, long = LandExtent.random_point
        precip = rand.round(2)
        FactoryBot.create(
          :precip,
          date: date,
          latitude: lat,
          longitude: long,
          precip: precip
        )
        grid = Precip.land_grid_for_date(date)
        expect(grid[lat, long]).to eq precip
      end
    end

    it "should store nil in grid for points without values" do
      grid = Precip.land_grid_for_date(date)
      lat, long = LandExtent.random_point
      expect(grid[lat, long]).to eq nil
    end
  end

  describe "create image for date or date range" do
    let(:earliest_date) { Date.current - 1.weeks }
    let(:latest_date) { Date.current }
    let(:empty_date) { earliest_date - 1.week }
    let(:lat) { 45.0 }
    let(:long) { -89.0 }

    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:precip, date: date, latitude: lat, longitude: long, precip: 1)
        FactoryBot.create(:precip_data_import, readings_on: date)
      end
    end

    it "should call ImageCreator when data present" do
      expect(Precip).to receive(:create_image_data).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      Precip.create_image(latest_date)
    end

    it "should create a cumulative data grid when given a date range" do
      expect(Precip).to receive(:create_image_data).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      Precip.create_image(latest_date, start_date: earliest_date)
    end

    it "should construct a data grid and convert units" do
      precips = Precip.where(date: latest_date)
      grid_mm = Precip.create_image_data(LandGrid.new, precips)
      grid_in = Precip.create_image_data(LandGrid.new, precips, "in")
      expect(grid_mm[lat, long].round(3)).to eq((grid_in[lat, long] * 25.4).round(3))
    end

    it "should return 'no_data.png' when data sources not loaded" do
      expect(Precip.create_image(empty_date)).to eq("no_data.png")
    end
  end
end
