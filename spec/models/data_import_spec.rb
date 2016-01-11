require 'rails_helper'

RSpec.describe DataImport, type: :model do

  describe '.days_to_load_for' do
    it 'lists the days that have not successfully completed' do
      expect(DataImport.days_to_load_for('insolation').first).to be_a(Date)
    end

    it 'only lists days that are within the defined range' do
      earliest_date = Date.today - DataImport::DaysBackWindow

      expect(DataImport.days_to_load_for('insolation').min).to be >= earliest_date
    end

    context 'no successful loads' do
      it 'returns all dates in window' do
        expect(DataImport.days_to_load_for('insolation').count).to be DataImport::DaysBackWindow
      end
    end

    context 'one successful load' do
      let!(:succesful_load) { DataImport.create!(
        data_type: 'insolation',
        status: 'completed',
        readings_from: Date.today - DataImport::DaysBackWindow.days)}

      it 'returns all other days' do
        dates_to_load = [Date.yesterday, Date.today - 2.days]

        expect(DataImport.days_to_load_for('insolation')).to match_array(dates_to_load)
      end
    end

    describe '.succesful_load' do
      it 'creates a new DataImport record' do
        expect{ DataImport.successful_load('insolation', Date.today) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status completed' do
        newRecord = DataImport.successful_load('insolation', Date.today)

        expect(newRecord.status).to eq 'completed'
      end
    end

    describe '.unsuccesful_load' do
      it 'creates a new DataImport record' do
        expect{ DataImport.unsuccessful_load('insolation', Date.today) }.to change(DataImport, :count).by 1
      end

      it 'creates a record with status attempted' do
        newRecord = DataImport.unsuccessful_load('insolation', Date.today)

        expect(newRecord.status).to eq 'attempted'
      end
    end
  end


end
