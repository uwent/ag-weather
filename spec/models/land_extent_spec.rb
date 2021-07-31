require 'rails_helper'

RSpec.describe LandExtent do

  N = 50
  S = 30
  W = 100
  E = 80
  I = 0.1

  describe '.inside?' do
    it 'is true for all four corners' do
      expect(LandExtent.inside?(N, W)).to be true
      expect(LandExtent.inside?(N, E)).to be true
      expect(LandExtent.inside?(S, W)).to be true
      expect(LandExtent.inside?(S, E)).to be true
    end

    it 'is false outside corners' do
      expect(LandExtent.inside?(N + I, W + I)).to be false
      expect(LandExtent.inside?(N + I, E - I)).to be false
      expect(LandExtent.inside?(S - I, W + I)).to be false
      expect(LandExtent.inside?(S - I, E - I)).to be false
    end
  end

  describe '.latitudes' do
    it 'returns list of latitudes' do
      expect(LandExtent.latitudes).to eq S..N
    end

    it 'returns list of longitudes' do
      expect(LandExtent.longitudes).to eq E..W
    end
  end

  describe '.each_point' do
    it 'should yield for each point in the range with step 0.1' do
      # 9801 = 81 latitude points * 121 longitude points
      grids = ((N - S + I) / I) * ((W - E + I) / I)
      expect { |b| LandExtent.each_point(0.1, &b) }.to yield_control.exactly(grids).times
    end
  end

end
