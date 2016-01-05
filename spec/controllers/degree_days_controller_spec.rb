require 'rails_helper'

RSpec.describe DegreeDaysController, type: :controller do

  describe '#show' do
    it 'returns a 200 status' do
      get :show, id: 4

      expect(response).to have_http_status(:ok)
    end

    it 'returns a map url' do
      get :show, id:4

      expect(response.body).to include('.img')
    end
  end
end