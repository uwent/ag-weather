require 'rails_helper'

RSpec.describe InsolationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#index' do
    it 'returns 200 status' do
      get :index

      expect(response).to have_http_status(:ok)
    end

    it 'returns paths to two images' do
      get :index

      expect(response_hash.length).to eq(2)
    end
  end
end