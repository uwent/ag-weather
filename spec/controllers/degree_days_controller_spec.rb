require "rails_helper"

RSpec.describe DegreeDaysController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:lat) { 43.015 }
  let(:long) { -89.49 }

  describe "#index" do
    let(:params) {
      {
        lat:,
        long:,
        start_date: Date.yesterday,
        method: "average",
        units: "C"
      }
    }

    before(:each) do
      FactoryBot.create(:weather_datum, latitude: lat.round(1), longitude: long.round(1))
    end

    it "is okay" do
      get(:index, params: {lat:, long:})

      expect(response).to have_http_status(:ok)
    end

    context "when the request is valid" do
      it "has the correct response structure" do
        get(:index, params:)

        expect(json.keys).to eq([:status, :info, :data])
        expect(json[:status]).to be_an(String)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data]).to be_an(Array)
        expect(json[:data].first.keys).to eq([:date, :min_temp, :max_temp, :value, :cumulative_value])
      end

      it "returns valid data when units are C" do
        get(:index, params:)

        data = json[:data].first
        expect(json[:info][:units]).to include("Celsius")
        expect(data[:min_temp]).to eq(8.9)
        expect(data[:max_temp]).to eq(12.5)
        expect(data[:value]).to eq(0.7)
        expect(data[:cumulative_value]).to eq(0.7)
      end

      it "returns valid data when units are F" do
        params.delete(:units)
        get(:index, params:)

        data = json[:data].first
        expect(json[:info][:units]).to include("Fahrenheit")
        expect(data[:min_temp]).to eq(48.0)
        expect(data[:max_temp]).to eq(54.5)
        expect(data[:value]).to eq(1.3)
        expect(data[:cumulative_value]).to eq(1.3)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        get(:index, params:)

        expect(json[:info][:lat]).to eq(lat.round(1))
        expect(json[:info][:long]).to eq(long.round(1))
      end

      it "can return a csv" do
        get(:index, params:, as: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when the request is not valid" do
      it "and has no latitude return no content" do
        params.delete(:lat)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("lat")
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("long")
      end

      it "and has no method uses default method" do
        params.delete(:method)
        get(:index, params:)

        expect(json[:info][:method]).to eq(DegreeDaysCalculator::METHOD)
      end
    end
  end

  describe "#dd_table" do
    let(:start_date) { "2022-01-01".to_date }
    let(:end_date) { "2022-01-04".to_date }
    let(:start_date_key) { start_date.to_s.to_sym }
    let(:end_date_key) { end_date.to_s.to_sym }
    let(:params) {
      {
        lat:,
        long:,
        models: "dd_32,dd_50_86"
      }
    }

    before :each do
      latitude = lat.round(1)
      longitude = long.round(1)
      (start_date..end_date).each do |date|
        FactoryBot.create(:weather_datum, latitude:, longitude:, date:)
        FactoryBot.create(:degree_day, latitude:, longitude:, date:, dd_32: 10, dd_50_86: 15)
      end
    end

    it "is okay" do
      get(:dd_table, params: {lat:, long:})

      expect(response).to have_http_status(:ok)
    end

    context "when the request is valid" do
      it "has the correct response structure" do
        get(:dd_table, params:)

        expect(json.keys).to eq([:status, :info, :data])
        expect(json[:status]).to be_an(String)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data]).to be_an(Hash)
        expect(json[:data].keys).to include(start_date_key)
        expect(json[:data][start_date_key].keys).to eq([:min_temp, :max_temp, :dd_32, :dd_50_86])
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        get(:dd_table, params:)

        expect(json[:info][:lat]).to eq(lat.round(1))
        expect(json[:info][:long]).to eq(long.round(1))
      end

      it "returns valid data when units are C" do
        get(:dd_table, params: params.merge(units: "C"))

        expect(json[:info][:units]).to include("Celsius")

        first_data = json[:data][start_date_key]
        last_data = json[:data][end_date_key]
        expect(first_data[:min_temp]).to eq(8.9)
        expect(first_data[:max_temp]).to eq(12.5)
        expect(first_data[:dd_32_none][:value]).to eq(5.56)
        expect(first_data[:dd_50_86][:value]).to eq(8.33)
        expect(last_data[:dd_32_none][:total]).to eq(22.22)
        expect(last_data[:dd_50_86][:total]).to eq(33.33)
      end

      it "returns valid data when units are F" do
        get(:dd_table, params:)

        expect(json[:info][:units]).to include("Fahrenheit")

        first_data = json[:data][start_date_key]
        last_data = json[:data][end_date_key]
        expect(first_data[:min_temp]).to eq(48.02)
        expect(first_data[:max_temp]).to eq(54.5)
        expect(first_data[:dd_32_none][:value]).to eq(10)
        expect(first_data[:dd_50_86][:value]).to eq(15)
        expect(last_data[:dd_32_none][:total]).to eq(40)
        expect(last_data[:dd_50_86][:total]).to eq(60)
      end
    end

    context "when the request is not valid" do
      it "and has no latitude return no content" do
        params.delete(:lat)
        get(:dd_table, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("lat")
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get(:dd_table, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("long")
      end

      it "and has no models uses default model" do
        params.delete(:models)
        get(:dd_table, params:)

        expect(json[:info][:models]).to eq(["dd_50_86"])
      end
    end
  end

  describe "#info" do
    it "is ok" do
      FactoryBot.create(:weather_datum)
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
