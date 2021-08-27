require "rails_helper"

RSpec.describe Insolation, type: :model do

  describe "construct land grid with insolation values for given date" do
    it "should constuct a land grid of insolation values" do
      expect(Insolation.land_grid_values_for_date(LandGrid.wisconsin_grid, Date.current)).to be_kind_of(LandGrid)
    end

    it "should have insolations stored for Wisconsin grid" do
      date = Date.current
      latitude = Wisconsin.max_lat
      longitude = Wisconsin.min_long
      FactoryBot.create(
        :insolation,
        date: date,
        latitude: latitude,
        longitude: longitude,
        insolation: 17.0)
      land_grid = Insolation.land_grid_values_for_date(LandGrid.wisconsin_grid, date)
      expect(land_grid[latitude, longitude]).to eq 17.0
    end

    it "should have insolations stored for WiMn grid" do
      date = Date.current
      latitude = WiMn.max_lat
      longitude = WiMn.min_long
      FactoryBot.create(
        :insolation,
        date: date,
        latitude: latitude,
        longitude: longitude,
        insolation: 25.0)
      land_grid = Insolation.land_grid_values_for_date(LandGrid.wi_mn_grid, date)
      expect(land_grid[latitude, longitude]).to eq 25.0
    end

    it "should have insolations stored for whole grid" do
      date = Date.current
      latitude = LandExtent.max_lat
      longitude = LandExtent.min_long
      FactoryBot.create(
        :insolation,
        date: date,
        latitude: latitude,
        longitude: longitude,
        insolation: 14.0)
      land_grid = Insolation.land_grid_values_for_date(LandGrid.new, date)
      expect(land_grid[latitude, longitude]).to eq 14.0
    end

    it "should store nil in grid for points without values" do
      land_grid = Insolation.land_grid_values_for_date(LandGrid.wisconsin_grid, Date.current)
      expect(land_grid[Wisconsin.max_lat, Wisconsin.min_long]).to be_nil
    end
  end
end
