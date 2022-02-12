require "rails_helper"

RSpec.describe Insolation, type: :model do
  describe "construct land grid with insolation values for given date" do
    it "should constuct a land grid of insolation values" do
      expect(Insolation.land_grid_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it "should have insolations stored" do
      date = Date.current
      lat = LandExtent.max_lat
      long = LandExtent.min_long
      FactoryBot.create(
        :insolation,
        date:,
        latitude: lat,
        longitude: long,
        insolation: 14.0
      )
      grid = Insolation.land_grid_for_date(date)
      expect(grid[lat, long]).to eq 14.0
    end

    it "should store nil in grid for points without values" do
      grid = Insolation.land_grid_for_date(Date.current)
      expect(grid[LandExtent.max_lat, LandExtent.min_long]).to be_nil
    end
  end

  describe "create image for date" do
    let(:earliest_date) { Date.current - 1.week }
    let(:latest_date) { Date.current }
    let(:empty_date) { earliest_date - 1.week }

    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:insolation_data_import, readings_on: date)
        FactoryBot.create(:insolation, date: date)
      end
    end

    it "should call ImageCreator when data sources loaded" do
      expect(Insolation).to receive(:create_image_data).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      Insolation.create_image(latest_date)
    end

    it "should create a cumulative data grid when given a date range" do
      expect(Insolation).to receive(:create_image_data).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      Insolation.create_image(latest_date, start_date: earliest_date)
    end

    it "should return 'no_data.png' when data sources not loaded" do
      expect(Insolation.create_image(empty_date)).to eq("no_data.png")
    end
  end
end
