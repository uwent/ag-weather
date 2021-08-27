require "rails_helper"

RSpec.describe WeatherController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  describe "#index" do
    let(:params) { {
      start_date: Date.yesterday,
      end_date: Date.yesterday,
      lat: 43,
      long: -89.7
    } }
    before(:each) do
      FactoryBot.create(:weather_datum)
    end

    context "when request is valid" do
      it "is okay" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :index, params: params
        expect(json).to be_an(Array)
        expect(json.first.keys).to match([:date, :min_temp, :avg_temp, :max_temp, :pressure])
      end

      it "can return a csv" do
        get :index, params: params, as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when the request is invalid" do
      it "and has no latitude return no content" do
        params.delete(:lat)
        get :index, params: params
        expect(json).to be_empty
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get :index, params: params
        expect(json).to be_empty
      end

      # it "and has no start date, return no content" do
      #   params.delete(:start_date)
      #   get :index, params: params
      #   expect(json).to be_empty
      # end

      # it "and has no end date, return no content" do
      #   params.delete(:end_date)
      #   get :index, params: params
      #   expect(json).to be_empty
      # end
    end
  end
end
