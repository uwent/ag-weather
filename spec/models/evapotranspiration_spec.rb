require 'rails_helper'

RSpec.describe Evapotranspiration, type: :model do
  EPSILON = 0.000001

  let(:new_et_point) { FactoryGirl.build(:evapotranspiration) }

  describe 'already_calculated?' do
    context 'ET point for same lat, long, and date exists' do
      before do
        FactoryGirl.create(:evapotranspiration)
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
        FactoryGirl.create(:weather_datum)
        FactoryGirl.create(:insolation)
      end

      it 'is true' do
        expect(new_et_point).to have_required_data
      end
    end

    context 'only weather data has been imported' do
      before do
        FactoryGirl.create(:weather_datum)
      end

      it 'is false' do
        expect(new_et_point).not_to have_required_data
      end
    end

    context 'only insolation data has been imported' do
      before do
        FactoryGirl.create(:insolation)
      end

      it 'is false' do
        expect(new_et_point).not_to have_required_data
      end
    end
  end

  describe 'calculate_et' do
    let(:insol) { FactoryGirl.create(:insolation) }
    let(:weather) { FactoryGirl.create(:weather_datum) }

    it 'should calculate a value for give insolation and weather' do
      expect(new_et_point.calculate_et(insol, weather)).to be_within(EPSILON).of(4.8552734) 
    end
  end
end
