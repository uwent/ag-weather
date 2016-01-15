require 'rails_helper'

RSpec.describe EvapotranspirationDatum, type: :model do
  let(:date) { Date.today }

  describe 'calculate_et_for_date' do
    let(:action) { EvapotranspirationDatum.calculate_et_for_date(date) }

    context 'insolation and weather data have successfully been imported' do
      before do
        DataImport.create_successful_load('weather', date)
        DataImport.create_successful_load('insolation', date)
        allow(EvapotranspirationDatum).to receive(:create_et_for_point)
      end

      it 'creates an et record in the db' do
        expect(EvapotranspirationDatum).to receive(:create_et_for_point)
        action
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

  describe 'create_et_for_point' do
    let(:lat) { 43 }
    let(:long) { 89.7 }

    context 'prereq data is loaded' do
      before do
        WeatherDatum.create(latitude: lat, longitude: long, date: date,
          max_temperature: 12.5,
          min_temperature: 8.9,
          avg_temperature: 10.7,
          vapor_pressure:  1.6
        )
        InsolationDatum.create(latitude: lat, longitude: long, date: date, insolation: 561)
      end

      it 'returns the potential et value' do
        expect(EvapotranspirationDatum.create_et_for_point(lat, long, date)).to be_a(EvapotranspirationDatum)
      end
    end

    context 'prereq data is not loaded' do
      it 'does not try and calculate a potential et' do
        expect(EvapotranspirationDatum).to_not receive(:et)
        EvapotranspirationDatum.create_et_for_point(lat, long, date)
      end
    end
  end

  describe '.create_et_data' do
    it 'runs calculate_et_for_date for every day returned by DataImport' do
      unloaded_days = [Date.yesterday, Date.today - 2.days]
      allow(DataImport).to receive(:days_to_load_for).with('evapotranspiration')
        .and_return(unloaded_days)

      expect(EvapotranspirationDatum).to receive(:calculate_et_for_date).exactly(unloaded_days.count).times

      EvapotranspirationDatum.create_et_data
    end
  end
end
