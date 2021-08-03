require 'rails_helper'

RSpec.describe InsolationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#show' do
    context 'when the request is valid' do
      it 'is okay' do
        get :show, params: { id: '2016-01-06' }

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        get :show, params: { id: '2016-01-06' }

        expect(response_hash.keys).to include('map')
      end

      it 'responds with the correct map name if data loaded' do
        filename = '/insolation_20160106.png'
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        InsolationDataImport.successful.create(readings_on: '2016-01-06')

        get :show, params: { id: '2016-01-06' }
        expect(response_hash['map']).to eq filename
      end

      it 'responds with the no data map name if data not loaded' do
        get :show, params: { id: '2016-01-06' }
        expect(response_hash['map']).to eq '/no_data.png'
      end
    end

    context 'when the request is invalid' do
      it 'returns yesterday\'s map' do
        filename = '/insolation_#{Date.yesterday.to_s(:number)}.png'
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        InsolationDataImport.successful.create(readings_on: Date.yesterday)

        get :show, params: { id: '' }

        expect(response_hash.keys).to match(['map'])
      end
    end
  end
end
