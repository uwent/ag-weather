require 'rails_helper'

RSpec.describe InsolationImporter, type: :model do

  describe '.fetch_day' do
    let(:date) { Date.today }

    context 'when valid data is found' do
      before do
        stub_request(:get, /prodserv1.ssec.wisc.edu\/insolation.*/)
          .to_return(body:
            "  1325       44.60        90.90/n" +  # point within WI
            "  1267       10.00        90.80/n" +  # point outside WI
            "-99999       44.60        90.70")     # point within WI, but invalid data
      end

      it 'adds only good insolation data to the DB' do
        expect{ InsolationImporter.fetch_day(date) }.to change(InsolationDatum, :count).by(2)
      end
    end
  end

  describe '.formatted_date' do
    it 'properly pads the date' do
      date = Date.new(2016,1,7)

      expect(InsolationImporter.formatted_date(date)).to eq('2016007')
    end

    it 'includes the day of the year' do
      date = Date.new(2016,6,6)

      expect(InsolationImporter.formatted_date(date)).to eq('2016158')
    end
  end

  describe '.inside_wi_mn_box?' do
    it 'is true for Kenosha, WI' do
      expect(InsolationImporter.inside_wi_mn_box?(42.5,87.8)).to be true
    end

    it 'is true for International Falls, MN' do
      expect(InsolationImporter.inside_wi_mn_box?(48.6,93.4)).to be true
    end

    it 'is false for Winnipeg, CANADA' do
      expect(InsolationImporter.inside_wi_mn_box?(50.1,97.2)).to be false
    end

    it 'is false for Detroit, MI' do
      expect(InsolationImporter.inside_wi_mn_box?(42.3,83.1)).to be false
    end
  end

end
