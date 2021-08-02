require 'rails_helper'

RSpec.describe WiMn do

  describe 'defines the correct extent' do

    it 'has a valid extent' do
      expect(WiMn.min_lat < WiMn.max_lat).to be true
      expect(WiMn.min_long < WiMn.max_long).to be true
    end

    it 'will create at least one grid point' do
      expect(WiMn.num_points > 0).to be true
    end

    it 'is smaller than the maximum extent' do
      expect(LandExtent.latitudes === WiMn.latitudes).to be true
      expect(LandExtent.longitudes === WiMn.longitudes).to be true
    end
  end

end
