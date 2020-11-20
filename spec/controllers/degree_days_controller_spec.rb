require 'rails_helper'

RSpec.describe DegreeDaysController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#show' do
    it 'is okay' do
      get :show, params: { id: '2016-01-07' }

      expect(response).to have_http_status(:ok)
    end

    it 'has the correct response structure' do
      get :show, params: { id: '2016-01-07' }

      expect(response_hash.first.keys).to match(['type', 'map'])
    end
  end

  describe '#index' do
    context 'when the request is valid' do
      it 'is okay' do
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        weather = FactoryBot.create(:weather_datum)
        params = {
          method: 'average',
          start_date: weather.date,
          lat: weather.latitude,
          long: weather.longitude,
          format: :json
        }
        get :index, params: params

        expect(response_hash.first.keys).to match(['date', 'value'])
      end
    end

    context 'when the request is not valid' do
      let!(:params) {{
          method: 'average',
          start_date: Date.current - 4.days,
          lat: 42.0,
          long: 89.0,
          format: :json
      }}

      it 'and has no latitude return no content' do
        params.delete(:lat)
        get :index, params: params

        expect(response_hash).to be_empty
      end

      it 'and has no longitude return no content' do
        params.delete(:long)
        get :index, params: params

        expect(response_hash).to be_empty
      end


      it 'and has no method return no content' do
        params.delete(:method)
        get :index, params: params

        expect(response_hash).to be_empty
      end
    end
  end
end
