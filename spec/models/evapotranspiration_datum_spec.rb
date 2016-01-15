require 'rails_helper'

RSpec.describe EvapotranspirationDatum, type: :model do
  let(:date) { Date.today }
  let(:lat) { 43 }
  let(:long) { 89.7 }

  describe 'already_done?' do
    context 'ET point for same lat, long, and date exists' do
      before do
        EvapotranspirationDatum.create(latitude: lat, longitude: long, date: date)
      end

      it 'is true' do
        new_et_point = EvapotranspirationDatum.new(latitude: lat, longitude: long, date: date)
        byebug
        expect(new_et_point.already_done?).to be true
      end
    end


  end


  # describe 'create_et_for_point' do


  #   context 'prereq data is loaded' do
  #     before do
  #       WeatherDatum.create(latitude: lat, longitude: long, date: date,
  #         max_temperature: 12.5,
  #         min_temperature: 8.9,
  #         avg_temperature: 10.7,
  #         vapor_pressure:  1.6
  #       )
  #       InsolationDatum.create(latitude: lat, longitude: long, date: date, insolation: 561)
  #     end

  #     it 'returns the potential et value' do
  #       expect(EvapotranspirationDatum.create_et_for_point(lat, long, date)).to be_a(EvapotranspirationDatum)
  #     end
  #   end

  #   context 'prereq data is not loaded' do
  #     it 'does not try and calculate a potential et' do
  #       expect(EvapotranspirationDatum).to_not receive(:et)
  #       EvapotranspirationDatum.create_et_for_point(lat, long, date)
  #     end
  #   end
  # end
end
