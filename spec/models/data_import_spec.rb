require 'rails_helper'

RSpec.describe DataImport, type: :model do

  describe '.days_to_load' do
    it 'lists the days that have not successfully successful' do
      expect(DataImport.days_to_load.first).to be_a(Date)
    end

    it 'only lists days that are within the defined range' do
      earliest_date = Date.current - DataImport::DAYS_BACK_WINDOW

      expect(DataImport.days_to_load.min).to be >= earliest_date
    end

    context 'no successful loads' do
      it 'returns all dates in window' do
        expect(DataImport.days_to_load.count).to be DataImport::DAYS_BACK_WINDOW
      end
    end

    context 'one successful load' do
      dates_to_load = DataImport.days_to_load
      reading_on = Date.current - DataImport::DAYS_BACK_WINDOW.days

      let!(:succesful_load) { DataImport.create!(
        status: 'successful',
        readings_on: reading_on)}

      it 'returns all other days' do
        expect(DataImport.days_to_load).to match_array(dates_to_load - [reading_on])
      end
    end

    describe '.create_succesful_load' do
      it 'creates a new DataImport record' do
        expect{DataImport.create_successful_load(Date.current) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status successful' do
        newRecord = DataImport.create_successful_load(Date.current)

        expect(newRecord.status).to eq 'successful'
      end
    end

    describe '.create_unsuccessful_load' do
      it 'creates a new DataImport record' do
        expect{DataImport.create_unsuccessful_load(Date.current) }.to change(DataImport, :count).by 1
      end

      it 'creates a reco1rd with status unsuccessful' do
        newRecord = DataImport.create_unsuccessful_load(Date.current)

        expect(newRecord.status).to eq 'unsuccessful'
      end
    end
  end
end
