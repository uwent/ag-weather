require 'rails_helper'

RSpec.describe EvapotranspirationsController, type: :controller do
  let(:response_hash) { JSON.parse(response.body) }

  describe '#index' do
    let(:latitude)  { 42.0 }
    let(:longitude) { 98.0 }
    before(:each) do
      1.upto(5) do |i|
        FactoryGirl.create(:evapotranspiration, latitude: latitude,
                           longitude: longitude, date: Date.current - i.days)
      end
    end

    context 'when request is valid' do
      before(:each) do
        @params = {start_date: Date.current - 4.days,
          end_date: Date.current - 1.days,
          lat: latitude,
          long: longitude,
          format: :json}
      end

      it 'is okay' do
        get :index, @params
        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response structure' do
        get :index, @params

        expect(response_hash).to be_an(Array)
        expect(response_hash[0]).to include("date", "value")
      end

      it 'has the correct number of elements' do
        get :index, @params

        expect(response_hash.length).to eq 4
      end
    end

    context 'when the request is invalid' do
      before(:each) do
        @params = {start_date: Date.current - 4.days,
          end_date: Date.current - 1.days,
          lat: latitude,
          long: longitude,
          format: :json}
      end

      it 'and has no latitude return no content' do
        @params.delete(:lat)
        get :index, @params

        expect(response_hash).to be_empty
      end

      it 'and has no longitude return no content' do
        @params.delete(:long)
        get :index, @params

        expect(response_hash).to be_empty
      end


      it 'and has no end_date return no content' do
        @params.delete(:end_date)
        get :index, @params

        expect(response_hash).to be_empty
      end

      it 'and has no start_date return no content' do
        @params.delete(:end_date)
        get :index, @params

        expect(response_hash).to be_empty
      end
    end
  end

  describe '#show' do
    context 'when the request is valid' do
      it 'is okay' do
        get :show, id: '2016-01-07'

        expect(response).to have_http_status(:ok)
      end

      it 'has the correct response of no map for date not loaded' do
        get :show, id: '2016-01-07'

        expect(response_hash['map']).to eq ('/no_data.png')
      end

      it 'has the correct response of map for date loaded' do
        filename = '/evapo_20160107.png'
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        EvapotranspirationDataImport.successful.create(readings_on: '2016-01-07')
        get :show, id: '2016-01-07'

        expect(response_hash['map']).to eq filename
      end
    end

    context 'when the request is invalid' do
      it 'without an date(id), result should be yesterday\'s map' do
        get :show, id: ''

        expect(response_hash.keys).to match(['map'])
      end
    end
  end

  describe '#calculate_et' do
    it 'correctly formats the response' do
      get :calculate_et, {
        max_temp: 12.5,
        min_temp: 8.9,
        avg_temp: 10.7,
        vapor_p: 1.6,
        insol: 561,
        doy: 123,
        lat: 43
      }

      response_hash = JSON.parse(response.body)

      expect(response_hash.keys).to match(['inputs','value'])
    end
  end
end
