require 'rails_helper'

RSpec.describe Evapotranspiration, type: :model do
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
    context 'when weather and insolation data imported' do
      before do
        FactoryGirl.create(:insolation)
        FactoryGirl.create(:weather_datum)
      end

      it 'is true' do
        expect(new_et_point.calculate_et).to be_truthy
      end

       it 'is persisted' do
        new_et_point.calculate_et
        expect(new_et_point).to be_persisted
      end

      it 'fills in the potential_et field' do
        new_et_point.calculate_et
        expect(new_et_point.reload.potential_et).to be_a(BigDecimal)
      end
    end

    context 'when only weather data present' do
      before do
        FactoryGirl.create(:weather_datum)
      end

      it 'is false' do
        expect(new_et_point.calculate_et).to be_falsey
      end

      it 'is not persisted' do
        new_et_point.calculate_et
        expect(new_et_point).not_to be_persisted
      end
    end

    context 'when only insolation data present' do
      before do
        FactoryGirl.create(:insolation)
      end

      it 'is false' do
        expect(new_et_point.calculate_et).to be_falsey
      end

      it 'is not persisted' do
        new_et_point.calculate_et
        expect(new_et_point).not_to be_persisted
      end
    end
  end
end
