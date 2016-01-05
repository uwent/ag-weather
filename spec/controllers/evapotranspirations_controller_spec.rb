require 'rails_helper'

RSpec.describe EvapotranspirationsController, type: :controller do

  describe '#index' do

    it 'returns 200 status' do
      get :index

      expect(response).to have_http_status(:ok)
    end

    it 'returns a path to an image' do
      get :index

      expect(response.body).to be_a(String)
    end

  end

  describe '#show' do
    it 'returns 200 status' do
      get :show, id: 123

      expect(response).to have_http_status(:ok)
    end
  end
end
