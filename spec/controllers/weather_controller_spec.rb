require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
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
end
