require 'rails_helper'

RSpec.describe InsolationImporter, type: :model do

  describe '.fetch_day' do
    let(:date) { Date.today }

    it 'returns true if data was saved to the DB' do
      expect(InsolationImporter.fetch_day(date)).to be true
    end

    it 'adds an insolation data point to the DB' do
      expect{ InsolationImporter.fetch_day(date) }.to change(InsolationDatum, :count)
    end

  end
end