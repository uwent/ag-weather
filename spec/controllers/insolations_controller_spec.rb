require 'rails_helper'

RSpec.describe InsolationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#show' do
    it 'returns 200 status' do
      get :show, id: '2016-01-06'

      expect(response).to have_http_status(:ok)
    end

    it 'returns paths to two images' do
      get :show, id: '2016-01-06'

      expect(response_hash.length).to eq(2)
    end
  end
end