require 'rails_helper'

RSpec.describe InsolationImporter, type: :model do

  describe '.fetch' do
    it 'runs fetch_day for every day returned by DataImport' do
      unloaded_days = [Date.yesterday, Date.current - 3.days]
      allow(InsolationDataImport).to receive(:days_to_load)
        .and_return(unloaded_days)

      expect(InsolationImporter).to receive(:fetch_day).exactly(unloaded_days.count).times

      InsolationImporter.fetch
    end
  end

  describe '.fetch_day' do
    let(:date) { Date.current }

    context 'when valid data is found' do
      before do
        stub_request(:get, /prodserv1.ssec.wisc.edu\/insolation.*/)
          .to_return(body:
            "  1325       44.60        90.90/n" +  # point within WI
            "  1267       10.00        90.80/n" +  # point outside WI
            "-99999       44.60        90.70")     # point within WI, but invalid data
      end

      it 'adds only good insolation data to the DB' do
         expect{ InsolationImporter.fetch_day(date) }.to change(Insolation, :count).by(1)
      end
    end
  end

  describe '.formatted_date' do
    it 'properly pads the date' do
      date = Date.new(2016, 1, 7)

      expect(InsolationImporter.formatted_date(date)).to eq('2016007')
    end

    it 'includes the day of the year' do
      date = Date.new(2016, 6, 6)

      expect(InsolationImporter.formatted_date(date)).to eq('2016158')
    end
  end

end
