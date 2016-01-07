require 'rails_helper'

RSpec.describe InsolationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#show' do
    context 'when the request is valid' do
      it 'is okay' do
        get :show, id: '2016-01-06'

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        get :show, id: '2016-01-06'

        expect(response_hash.keys).to include('west_map', 'east_map')
      end
    end

    context 'when the request is invalid' do
      it 'is no content'
    end
  end
end