require 'rails_helper'

RSpec.describe DegreeDaysController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#show' do
    it 'is okay' do
      get :show, id: '2016-01-07'

      expect(response).to have_http_status(:ok)
    end

    it 'has the correct response structure' do
      get :show, id: '2016-01-07'

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
        get :index

        expect(response_hash.keys).to match(['degree_days'])
      end
    end

    context 'when the request is not valid' do
      it 'is no content'
    end
  end
end
