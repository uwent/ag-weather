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
    it 'cycles through each point'
  end

end
