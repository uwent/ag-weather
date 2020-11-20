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
        weather = FactoryBot.create(:weather_datum)
        params = {
          start_date: weather.date,
          end_date: weather.date,
          lat: weather.latitude,
          long: weather.longitude,
          format: :json
        }

        get :index, params: params

        expect(response_hash).to be_an(Array)
        expect(response_hash.first.keys).to match(%w{date min_temp avg_temp max_temp pressure})
      end
    end

    context 'when the request is invalid' do
      let!(:params) {{
        end_date: Date.current - 2.days,
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

      it 'and has no start date, return no content' do
        params.delete(:start_date)
        get :index, params: params

        expect(response_hash).to be_empty
      end

      it 'and has no end date, return no content' do
        params.delete(:end_date)
        get :index, params: params

        expect(response_hash).to be_empty
      end
    end
  end
end
