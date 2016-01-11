require 'rails_helper'

RSpec.describe DataImport, type: :model do

  describe '.days_to_load_for' do
    it 'lists the days that have not successfully successful' do
      expect(DataImport.days_to_load_for('insolation').first).to be_a(Date)
    end

    it 'only lists days that are within the defined range' do
      earliest_date = Date.today - DataImport::DAYS_BACK_WINDOW

      expect(DataImport.days_to_load_for('insolation').min).to be >= earliest_date
    end

    context 'no successful loads' do
      it 'returns all dates in window' do
        expect(DataImport.days_to_load_for('insolation').count).to be DataImport::DAYS_BACK_WINDOW
      end
    end

    context 'one successful load' do
      let!(:succesful_load) { DataImport.create!(
        data_type: 'insolation',
        status: 'successful',
        readings_from: Date.today - DataImport::DAYS_BACK_WINDOW.days)}

      it 'returns all other days' do
        dates_to_load = [Date.yesterday, Date.today - 2.days]

        expect(DataImport.days_to_load_for('insolation')).to match_array(dates_to_load)
      end
    end

    describe '.create_succesful_load' do
      it 'creates a new DataImport record' do
        expect{ DataImport.create_successful_load('insolation', Date.today) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status successful' do
        newRecord = DataImport.create_successful_load('insolation', Date.today)

        expect(newRecord.status).to eq 'successful'
      end
    end

    describe '.create_unsuccessful_load' do
      it 'creates a new DataImport record' do
        expect{ DataImport.create_unsuccessful_load('insolation', Date.today) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status unsuccessful' do
        newRecord = DataImport.create_unsuccessful_load('insolation', Date.today)

        expect(newRecord.status).to eq 'unsuccessful'
      end
    end
  end


end
