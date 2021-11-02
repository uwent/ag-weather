require 'rails_helper'

RSpec.describe Evapotranspiration, type: :model do

  let(:new_et_point) { FactoryBot.build(:evapotranspiration) }

  describe 'already_calculated?' do
    context 'ET point for same lat, long, and date exists' do
      before do
        FactoryBot.create(:evapotranspiration)
      end

      it 'is true' do
        expect(new_et_point).to be_already_calculated
      end
    end

    context 'No other ET points exist' do
      it 'is false' do
        expect(new_et_point).not_to be_already_calculated
      end
    end
  end

  describe 'has_required_data?' do
    context 'weather and and insolation data imported' do
      before do
        FactoryBot.create(:weather_datum)
        FactoryBot.create(:insolation)
      end

      it 'is true' do
        expect(new_et_point).to have_required_data
      end
    end

    context 'only weather data has been imported' do
      before do
        FactoryBot.create(:weather_datum)
      end

      it 'is false' do
        expect(new_et_point).not_to have_required_data
      end
    end

    context 'only insolation data has been imported' do
      before do
        FactoryBot.create(:insolation)
      end

      it 'is false' do
        expect(new_et_point).not_to have_required_data
      end
    end
  end

  describe 'calculate_et' do
    let(:insol) { FactoryBot.create(:insolation) }
    let(:weather) { FactoryBot.create(:weather_datum) }

    it 'should calculate a value for give insolation and weather' do
      expect(new_et_point.calculate_et(insol.insolation, weather)).to be_within(LandGrid::EPSILON).of(4.8552734) 
    end
  end

  describe "construct land grid with evapotranspiration for given date" do
    it 'should constuct a land grid' do
      expect(Evapotranspiration.land_grid_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it 'should have evapotranspirations stored in the grid' do
      date = Date.current
      lat = LandExtent.max_lat
      long = LandExtent.min_long

      FactoryBot.create(
        :evapotranspiration,
        date: date,
        latitude: lat,
        longitude: long,
        potential_et: 23.4
      )

      grid = Evapotranspiration.land_grid_for_date(date)
      expect(grid[lat, long]).to eq 23.4
    end

    it 'should store nil in grid for points without values' do
      grid = Evapotranspiration.land_grid_for_date(Date.current)
      expect(grid[LandExtent.max_lat, LandExtent.min_long]).to be_nil
    end
  end
end
