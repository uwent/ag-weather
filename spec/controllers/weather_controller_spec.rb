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
        weather = FactoryGirl.create(:weather_datum)
        params = {start_date: weather.date,
          end_date: weather.date,
          lat: weather.latitude,
          long: weather.longitude,
          format: :json
        }

        get :index, params

        expect(response_hash).to be_an(Array)
        expect(response_hash.first.keys).to match(%w{date min_temp avg_temp max_temp pressure})
      end
    end

    context 'when the request is invalid' do
      it 'is no content'
    end
  end
end
