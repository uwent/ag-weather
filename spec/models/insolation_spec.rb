require "rails_helper"

RSpec.describe Insolation, type: :model do

  describe "construct land grid with insolation recordings for given date" do
    it 'should constuct a land grid of insolation recordings' do
      expect(Insolation.land_grid_values_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it 'should have insolations stored in the grid' do
      date = Date.current
      latitude = WeatherExtent::N_LAT
      longitude = WeatherExtent::E_LONG
      FactoryBot.create(
        :insolation,
        date: date,
        latitude: latitude,
        longitude: longitude,
        insolation: 17.0)
      land_grid = Insolation.land_grid_values_for_date(date)
      expect(land_grid[latitude, longitude]).to eq 17.0
    end

    it 'should store nil in grid for points without values' do
      land_grid = Insolation.land_grid_values_for_date(Date.current)
      expect(land_grid[WeatherExtent::N_LAT, WeatherExtent::E_LONG]).to be_nil
    end
  end
end
