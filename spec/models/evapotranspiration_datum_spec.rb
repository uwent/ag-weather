require 'rails_helper'

RSpec.describe EvapotranspirationDatum, type: :model do
  describe 'calculate_et_for_date' do
    let(:date) { Date.today }
    let(:action) { EvapotranspirationDatum.calculate_et_for_date(date) }

    context 'insolation and weather data have successfully been imported' do
      before do
        DataImport.create_successful_load('weather', date)
        DataImport.create_successful_load('insolation', date)
      end

      it 'creates an et record in the db' do
        expect{ action }.to change(EvapotranspirationDatum, :count)
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
end
