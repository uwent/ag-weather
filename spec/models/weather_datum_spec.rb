require "rails_helper"

RSpec.describe WeatherDatum, type: :model do

  describe "construct land grid with weather data for given date" do
    it 'should constuct a land grid' do
      expect(WeatherDatum.land_grid_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it 'should have weather data stored in the grid' do
      date = Date.current
      latitude = WiMn::N_LAT
      longitude = WiMn::E_LONG
      FactoryGirl.create(:weather_datum, date: date, latitude: latitude,
                         longitude: longitude)
      land_grid = WeatherDatum.land_grid_for_date(date)
      expect(land_grid[latitude, longitude]).to be_kind_of(WeatherDatum)
    end

    it 'should store nil in grid for points without values' do
      land_grid = WeatherDatum.land_grid_for_date(Date.current)
      expect(land_grid[WiMn::N_LAT, WiMn::E_LONG]).to be_nil
    end
  end
end
