require 'rails_helper'

RSpec.describe EvapotranspirationImporter, type: :model do
  let(:date) { Date.today }

  describe 'calculate_et_for_date' do
    let(:action) { EvapotranspirationImporter.calculate_et_for_date(date) }

    context 'insolation and weather data have successfully been imported' do
      before do
        DataImport.create_successful_load('weather', date)
        DataImport.create_successful_load('insolation', date)
      end

      it 'adds a data_import record' do
        expect{ action }.to change(DataImport.successful, :count)
      end
    end

    context 'insolation and weather data not imported' do
      it 'will return a record not found error' do
        expect{ action }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will create an unsuccessful data import record' do
        expect{ action rescue nil }.to change(DataImport.unsuccessful, :count)
      end
    end
  end

  describe '.create_et_data' do
    it 'runs calculate_et_for_date for every day returned by DataImport' do
      unloaded_days = [Date.yesterday, Date.today - 2.days]
      expect(DataImport).to receive(:days_to_load_for).with('evapotranspiration')
        .and_return(unloaded_days)

      expect(EvapotranspirationImporter).to receive(:calculate_et_for_date).exactly(unloaded_days.count).times

      EvapotranspirationImporter.create_et_data
    end
  end

end