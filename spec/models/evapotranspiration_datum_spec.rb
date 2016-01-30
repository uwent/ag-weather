require 'rails_helper'

RSpec.describe EvapotranspirationDatum, type: :model do
  let(:date) { Date.today }
  let(:lat) { 43 }
  let(:long) { 89.7 }
  let(:new_et_point) { EvapotranspirationDatum.new(latitude: lat, longitude: long, date: date) }

  describe 'already_calculated?' do
    context 'ET point for same lat, long, and date exists' do
      before do
        EvapotranspirationDatum.create(latitude: lat, longitude: long, date: date)
      end

      it 'is true' do
        expect(new_et_point).to be_already_calculated
      end
    end

    context 'No other ET points exist' do
      it 'is false' do
        expect(new_et_point).not_to be_already_calculated
      end
    end
  end

  describe 'has_required_data?' do
    context 'weather and and insolation data imported' do
      before do
        WeatherDatum.create(latitude: lat, longitude: long, date: date)
        InsolationDatum.create(latitude: lat, longitude: long, date: date)
      end

      it 'is true' do
        expect(new_et_point).to have_required_data
      end
    end

    context 'only weather data has been imported' do
      before do
        WeatherDatum.create(latitude: lat, longitude: long, date: date)
      end

      it 'is false' do
        expect(new_et_point).not_to have_required_data
      end
    end
  end

  describe 'calculate_et' do
    context 'when weather and insolation data imported' do
      before do
        InsolationDatum.create(latitude: lat, longitude: long, date: date, insolation: 561)
        WeatherDatum.create(latitude: lat, longitude: long, date: date,
          max_temperature: 12.5,
          min_temperature: 8.9,
          avg_temperature: 10.7,
          vapor_pressure:  1.6
        )
      end

      it 'fills in the potential_et field' do
        new_et_point.calculate_et
        expect(new_et_point.reload.potential_et).to be_a(BigDecimal)
      end

      it 'is true' do
        new_et_point.calculate_et
        expect(new_et_point).to be_persisted
      end

      it 'saves itself' do
        new_et_point.calculate_et

        expect(new_et_point.reload.id).to_not be nil
      end
    end
  end
end
