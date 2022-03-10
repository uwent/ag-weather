require "rails_helper"

RSpec.describe WeatherController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:lat) { 42.0 }
  let(:long) { -98.0 }
  let(:latest_date) { DataImport.latest_date }
  let(:earliest_date) { latest_date - 1.week }
  let(:empty_date) { "2000-01-01" }

  describe "#index" do
    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date:)
        FactoryBot.create(:weather_data_import, readings_on: date)
      end
    end

    context "when request is valid" do
      let(:params) {
        {
          lat:,
          long:,
          start_date: earliest_date,
          end_date: latest_date
        }
      }

      it "is okay" do
        get(:index)
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:index, params:)
        expect(json[:data]).to be_an(Array)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data].first.keys).to match([
          :date,
          :min_temp,
          :max_temp,
          :avg_temp,
          :dew_point,
          :pressure,
          :hours_rh_over_90,
          :avg_temp_rh_over_90
        ])
      end

      it "has the correct number of elements" do
        get(:index, params:)
        expect(json[:data].length).to eq((earliest_date..latest_date).count)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get(:index, params:)
        expect(json[:info][:start_date]).to eq(latest_date.beginning_of_year.to_s)
      end

      it "defaults end_date to today" do
        params.delete(:end_date)
        get(:index, params:)
        expect(json[:info][:end_date]).to eq(latest_date.to_s)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        lat = 43.015
        long = -89.49
        params.update({
          lat:,
          long:
        })
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

    context "when the request is invalid" do
      let(:params) {
        {
          lat:,
          long:,
          start_date: earliest_date,
          end_date: latest_date
        }
      }

      it "and has no latitude return no data" do
        params.delete(:lat)
        get(:index, params:)
        expect(json[:status]).to eq("no data")
        expect(json[:data]).to be_empty
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get(:index, params:)
        expect(json[:status]).to eq("no data")
        expect(json[:data]).to be_empty
      end
    end
  end

  describe "#show" do
    let(:date) { latest_date }
    let(:filename) { WeatherDatum.image_name(date) }

    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:weather_data_import, readings_on: date)
        10.upto(15) do |lat|
          10.upto(15) do |long|
            FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date: date)
          end
        end
      end
    end

    context "when the request is valid" do
      it "is okay" do
        get(:show, params: {id: date})
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:show, params: {id: date})
        expect(json.keys).to eq([:params, :compute_time, :map])
      end

      it "responds with the correct map name if data loaded" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get(:show, params: {id: date})
        expect(json[:map]).to eq("/#{filename}")
      end

      it "returns the correct image when given a units param" do
        units = "C"
        file = WeatherDatum.image_name(date, units)
        allow(ImageCreator).to receive(:create_image).and_return(file)
        get(:show, params: {id: date, units:})
        expect(json[:map]).to eq("/#{file}")
      end

      it "has the correct response of no map for date not loaded" do
        get(:show, params: {id: empty_date})
        expect(json[:map]).to eq("/no_data.png")
      end

      it "shows the image in the browser when format=png" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get(:show, params: {id: date, format: :png})
        expect(response.body).to include("<img src=/#{filename}")
      end
    end

    context "when the request is invalid" do
      it "returns the most recent map" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get(:show, params: {id: "foo"})
        expect(json[:map]).to eq("/#{filename}")
      end

      it "throws error on bad units" do
        expect { get(:show, params: {id: date, units: "foo"}) }.to raise_error ActionController::BadRequest
      end
    end
  end

  describe "#all_for_date" do
    let(:date) { latest_date }
    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date:)
        FactoryBot.create(:weather_data_import, readings_on: date)
      end
    end

    context "when the request is valid" do
      it "is okay" do
        get(:all_for_date, params: {date:})
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:all_for_date, params: {date:})
        expect(json.keys).to match([:status, :info, :data])
      end

      it "returns valid data" do
        get(:all_for_date, params: {date:})
        expect(json[:status]).to eq("OK")
        expect(json[:info]).to be_an(Hash)
        expect(json[:data]).to be_an(Array)
        expect(json[:data][0].keys).to match([:lat, :long, :min_temp, :max_temp, :avg_temp, :dew_point, :pressure, :hours_rh_over_90, :avg_temp_rh_over_90])
      end

      it "can return a csv" do
        get(:all_for_date, params: {date:}, as: :csv)
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when date is valid but has no data" do
      it "returns empty data" do
        get(:all_for_date, params: {date: empty_date})
        expect(json[:info][:date]).to eq(empty_date.to_s)
        expect(json[:data]).to be_empty
      end
    end

    context "when params are empty" do
      it "defaults to most recent data" do
        get(:all_for_date)
        expect(json[:info][:date]).to eq(latest_date.to_s)
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
