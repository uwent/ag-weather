require 'rails_helper'

RSpec.describe WiMn do

  describe '.inside_wi_mn_box?' do
    it 'is true for Kenosha, WI' do
      expect(WiMn.inside_wi_mn_box?(42.5, 87.8)).to be true
    end

    it 'is true for International Falls, MN' do
      expect(WiMn.inside_wi_mn_box?(48.6, 93.4)).to be true
    end

    it 'is false for Winnipeg, CANADA' do
      expect(WiMn.inside_wi_mn_box?(50.1, 97.2)).to be false
    end

    it 'is false for Detroit, MI' do
      expect(WiMn.inside_wi_mn_box?(42.3, 83.1)).to be false
    end
  end

  describe '.each_point' do
    it 'should yield for each point in the range with step 0.1' do
      # 9801 = 81 latitude points * 121 longitude points
      expect { |b| WiMn.each_point(0.1, &b) }.to yield_control.exactly(9801).times
    end

    it 'should yield for each point in the range without step' do
      # 9801 = 81 latitude points * 121 longitude points
      expect { |b| WiMn.each_point(0.1, &b) }.to yield_control.exactly(9801).times
    end

    it 'should yield for each point in the range with step 1' do
      # 117 = 9 latitude points * 13 longitudes
      expect { |b| WiMn.each_point(1, &b) }.to yield_control.exactly(117).times
    end
    
  end

end
