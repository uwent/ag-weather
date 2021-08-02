require 'rails_helper'

RSpec.describe LandExtent do

  LATS = 38..50
  LONS = 82..98
  STEP = 0.1

  describe 'basic elements' do
    it 'has correct default values' do
      expect(LandExtent.latitudes).to eq(LATS)
      expect(LandExtent.longitudes).to eq(LONS)
      expect(LandExtent.step).to eq(STEP)
    end

    it 'has correct values for lat/long min/max' do
      expect(LandExtent.min_lat).to eq(LandExtent.latitudes.min)
      expect(LandExtent.max_lat).to eq(LandExtent.latitudes.max)
      expect(LandExtent.min_long).to eq(LandExtent.longitudes.min)
      expect(LandExtent.max_long).to eq(LandExtent.longitudes.max)

      expect(LandExtent.min_lat).to eq(LATS.min)
      expect(LandExtent.max_lat).to eq(LATS.max)
      expect(LandExtent.min_long).to eq(LONS.min)
      expect(LandExtent.max_long).to eq(LONS.max)
    end
  end

  describe '.inside?' do
    it 'insides are inside' do
      expect(LandExtent.inside?(LATS.min, LONS.min)).to be true
      expect(LandExtent.inside?(LATS.min, LONS.max)).to be true
      expect(LandExtent.inside?(LATS.max, LONS.min)).to be true
      expect(LandExtent.inside?(LATS.max, LONS.max)).to be true
    end

    it 'outsides are outside' do
      expect(LandExtent.inside?(LATS.min - 1, LONS.min - 1)).to be false
      expect(LandExtent.inside?(LATS.max + 1, LONS.max + 1)).to be false
    end
  end

end
