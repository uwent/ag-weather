require 'rails_helper'

RSpec.describe DataImport, type: :model do

  describe '.days_to_load_for' do
    it 'lists the days that have not successfully successful' do
      expect(InsolationDataImport.days_to_load_for.first).to be_a(Date)
    end

    it 'only lists days that are within the defined range' do
      earliest_date = Date.current - DataImport::DAYS_BACK_WINDOW

      expect(InsolationDataImport.days_to_load_for.min).to be >= earliest_date
    end

    context 'no successful loads' do
      it 'returns all dates in window' do
        expect(InsolationDataImport.days_to_load_for.count).to be DataImport::DAYS_BACK_WINDOW
      end
    end

    context 'one successful load' do
      let!(:succesful_load) { InsolationDataImport.create!(
        status: 'successful',
        readings_on: Date.current - DataImport::DAYS_BACK_WINDOW.days)}

      it 'returns all other days' do
        dates_to_load = [Date.yesterday, Date.current - 2.days]

        expect(InsolationDataImport.days_to_load_for).to match_array(dates_to_load)
      end
    end

    describe '.create_succesful_load' do
      it 'creates a new DataImport record' do
        expect{InsolationDataImport.create_successful_load(Date.current) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status successful' do
        newRecord = InsolationDataImport.create_successful_load(Date.current)

        expect(newRecord.status).to eq 'successful'
      end
    end

    describe '.create_unsuccessful_load' do
      it 'creates a new DataImport record' do
        expect{InsolationDataImport.create_unsuccessful_load(Date.current) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status unsuccessful' do
        newRecord = InsolationDataImport.create_unsuccessful_load(Date.current)

        expect(newRecord.status).to eq 'unsuccessful'
      end
    end
  end
end
