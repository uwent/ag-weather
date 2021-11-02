require 'rails_helper'

RSpec.describe Precip, type: :model do
  
  describe "construct land grid grid with precip values for given date" do
    let(:date) { Date.current }

    it "should construct a land grid of precip values" do
      expect(Precip.land_grid_for_date(date)).to be_kind_of(LandGrid)
    end

    it "should have precips stored" do
      1.upto(5) do
        lat, long = LandExtent.random_point
        precip = rand().round(2)
        FactoryBot.create(
          :precip,
          date: date,
          latitude: lat,
          longitude: long,
          precip: precip)
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

  describe "create image for date" do
    let(:date) { Date.yesterday }

    before(:each) do
      FactoryBot.create(:precip_data_import, readings_on: date)
    end

    it "should call ImageCreator when data sources loaded" do
      expect(Precip).to receive(:land_grid_for_date).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      Precip.create_image(date)
    end

    it "should return 'no_data.png' when data sources not loaded" do
      expect(Precip.create_image(date - 1.day)).to eq("no_data.png")
    end
  end

end
