require 'rails_helper'

RSpec.describe EvapotranspirationImporter, type: :model do

  let(:date) { Date.current }

  describe 'calculate_et_for_date' do
    let(:action) { EvapotranspirationImporter.calculate_et_for_date(date) }

    context 'insolation and weather data have successfully been imported' do
      before do
        WeatherDataImport.succeed(date)
        InsolationDataImport.succeed(date)
      end

      it 'adds a data_import record' do
        expect{ action }.to change(DataImport.successful, :count)
      end

      it 'adds a new evapotranspiration record' do
        Insolation.create(
          latitude: WeatherExtent::S_LAT,
          longitude: WeatherExtent::E_LONG,
          insolation: 1257.0,
          date: date
        )
        WeatherDatum.create(
          latitude: WeatherExtent::S_LAT,
          longitude: WeatherExtent::E_LONG,
          date: date,
          max_temperature: 15.0,
          min_temperature: 5.0,
          avg_temperature: 10.0,
          vapor_pressure: 0.70
        )
        expect{ action }.to change(Evapotranspiration, :count)
      end
    end

    context 'insolation and weather data not imported' do
      it 'will create an unsuccessful data import record' do
        expect{ action }.to change(DataImport.unsuccessful, :count)
      end
    end
  end

  describe '.create_et_data' do
    it 'runs calculate_et_for_date for every day returned by DataImport' do
      unloaded_days = [Date.yesterday, Date.current - 2.days]
      expect(EvapotranspirationDataImport).to receive(:days_to_load)
        .and_return(unloaded_days)

      expect(EvapotranspirationImporter).to receive(:calculate_et_for_date).exactly(unloaded_days.count).times

      EvapotranspirationImporter.create_et_data
    end
  end

end
