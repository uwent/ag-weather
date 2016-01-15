require 'rails_helper'

RSpec.describe EvapotranspirationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#index' do
    context 'when request is valid' do
      it 'is okay' do
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        get :index

        expect(response_hash).to be_an(Array)
      end
    end

    context 'when the request is invalid' do
      it 'is no content'
    end
  end

  describe '#show' do
    context 'when the request is valid' do
      it 'is okay' do
        get :show, id: '2016-01-07'

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        get :show, id: '2016-01-07'

        expect(response_hash.keys).to match(['map'])
      end
    end

    context 'when the request is invalid' do
      it 'is no content'
    end
  end

  describe '#calculate_et' do
    it 'correctly formats the response' do
      get :calculate_et, {
        max_temp: 12.5,
        min_temp: 8.9,
        avg_temp: 10.7,
        vapor_p: 1.6,
        insol: 561,
        doy: 123,
        lat: 43
      }

      response_hash = JSON.parse(response.body)

      expect(response_hash.keys).to match(['inputs','value'])
    end
  end
end
