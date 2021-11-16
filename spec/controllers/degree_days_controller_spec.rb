require "rails_helper"

RSpec.describe DegreeDaysController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  # describe "#show" do
  #   it "is okay" do
  #     get :show, params: { id: "2016-01-07" }

  #     expect(response).to have_http_status(:ok)
  #   end

  #   it "has the correct response structure" do
  #     get :show, params: { id: "2016-01-07" }

  #     expect(json.first.keys).to match(["type", "map"])
  #   end
  # end

  describe "#index" do
    let(:params) {
      {
        lat: 43.0,
        long: -89.7,
        start_date: Date.yesterday,
        method: "average",
        units: "C"
      }
    }
    before(:each) do
      FactoryBot.create(:weather_datum)
    end

    it "is okay" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    context "when the request is valid" do
      it "has the correct response structure" do
        get :index, params: params
        expect(json.keys).to eq([:status, :info, :data])
        expect(json[:status]).to be_an(String)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data]).to be_an(Array)
        expect(json[:data].first.keys).to eq([:date, :min_temp, :max_temp, :value, :cumulative_value])
      end

      it "returns valid data when units are C" do
        get :index, params: params
        data = json[:data].first
        expect(json[:info][:units]).to include("Celcius")
        expect(data[:min_temp]).to eq(8.9)
        expect(data[:max_temp]).to eq(12.5)
        expect(data[:value]).to eq(0.7)
        expect(data[:cumulative_value]).to eq(0.7)
      end

      it "returns valid data when units are F" do
        params.delete(:units)
        get :index, params: params
        data = json[:data].first
        expect(json[:info][:units]).to include("Fahrenheit")
        expect(data[:min_temp]).to eq(48.0)
        expect(data[:max_temp]).to eq(54.5)
        expect(data[:value]).to eq(1.3)
        expect(data[:cumulative_value]).to eq(1.3)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        lat = 43.015
        long = -89.49
        params.update({
          lat: lat,
          long: long
        })
        get :index, params: params
        expect(json[:info][:lat]).to eq(lat.round(1))
        expect(json[:info][:long]).to eq(long.round(1))
      end

      it "can return a csv" do
        get :index, params: params, as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when the request is not valid" do
      it "and has no latitude return no content" do
        params.delete(:lat)
        get :index, params: params
        expect(json[:status]).to eq("no data")
        expect(json[:data]).to be_empty
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get :index, params: params
        expect(json[:status]).to eq("no data")
        expect(json[:data]).to be_empty
      end

      it "and has no method uses default method" do
        params.delete(:method)
        get :index, params: params
        expect(json[:info][:method]).to eq(DegreeDaysCalculator::METHOD)
      end
    end
  end
end
