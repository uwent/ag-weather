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
        date: date,
        latitude: lat,
        longitude: long,
        insolation: 14.0)
      grid = Insolation.land_grid_for_date(date)
      expect(grid[lat, long]).to eq 14.0
    end

    it "should store nil in grid for points without values" do
      grid = Insolation.land_grid_for_date(Date.current)
      expect(grid[LandExtent.max_lat, LandExtent.min_long]).to be_nil
    end
  end
end
