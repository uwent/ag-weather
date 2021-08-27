require "rails_helper"

RSpec.describe EvapotranspirationsController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  describe "#index" do
    let(:start_date) { Date.current - 2.weeks }
    let(:end_date) { Date.current - 1.week }
    let(:lat)  { 42.0 }
    let(:long) { -98.0 }
    before(:each) do
      (start_date..end_date).each do |date|
        FactoryBot.create(:evapotranspiration, latitude: lat, longitude: long, date: date)
        FactoryBot.create(:evapotranspiration_data_import, readings_on: date)
      end
    end

    context "when request is valid" do
      let(:params) {{
        lat: lat,
        long: long,
        start_date: start_date,
        end_date: end_date
      }}

      it "is okay" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :index, params: params
        expect(json[:data]).to be_an(Array)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data][0].keys).to match([:date, :value])
      end

      it "has the correct number of elements" do
        get :index, params: params
        expect(json[:data].length).to eq((start_date..end_date).count)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get :index, params: params
        expect(json[:info][:start_date]).to eq(start_date.beginning_of_year.to_s)
      end

      it "defaults end_date to today" do
        params.delete(:end_date)
        get :index, params: params
        expect(json[:info][:end_date]).to eq(Date.current.to_s)
      end

      it "can return a csv" do
        get :index, params: params, as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when the request is invalid" do
      let(:params) {{
        lat: lat,
        long: long,
        start_date: start_date,
        end_date: end_date
      }}

      it "and has no latitude return no data" do
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
    end
  end

  describe "#show" do
    let(:date) { Date.yesterday }
    let(:filename) { "/evapo_#{date.to_s(:number)}.png" }
    before(:each) do
      FactoryBot.create(:evapotranspiration, date: date)
      FactoryBot.create(:evapotranspiration_data_import, readings_on: date)
    end

    context "when the request is valid" do
      it "is okay" do
        get :show, params: { id: date }
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :show, params: { id: date }
        expect(json.keys).to eq([:map])
      end

      it "responds with the correct map name if data loaded" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get :show, params: { id: date }
        expect(json[:map]).to eq(filename)
      end

      it "has the correct response of no map for date not loaded" do
        get :show, params: { id: date }
        expect(json[:map]).to eq("/no_data.png")
      end

      it "shows the image in the browser when format=png" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get :show, params: { id: date, format: :png }
        expect(response.body).to include("<img src=#{filename}")
      end
    end

    context "when the request is invalid" do
      it "returns the most recent map" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        get :show, params: { id: "foo" }
        expect(json[:map]).to eq(filename)
      end
    end
  end

  describe "#all_for_date" do
    let(:date) { Date.current - 1.month }
    let(:date2) { Date.current - 1.week }
    let(:empty_date) { Date.current - 1.year }
    before(:each) do
      FactoryBot.create(:evapotranspiration, date: date)
      FactoryBot.create(:evapotranspiration_data_import, readings_on: date)
      FactoryBot.create(:evapotranspiration, date: date2)
      FactoryBot.create(:evapotranspiration_data_import, readings_on: date2)
    end

    context "when the request is valid" do
      it "is okay" do
        get :all_for_date, params: { date: date }
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :all_for_date, params: { date: date }
        expect(json.keys).to match([:status, :info, :data])
      end

      it "returns valid data" do
        get :all_for_date, params: { date: date }
        expect(json[:status]).to eq("OK")
        expect(json[:info]).to be_an(Hash)
        expect(json[:data]).to be_an(Array)
        expect(json[:data][0].keys).to match([:lat, :long, :value])
      end

      it "can return a csv" do
        get :all_for_date, params: { date: date }, as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when date is valid but has no data" do
      it "returns empty data" do
        get :all_for_date, params: { date: empty_date }
        expect(json[:info][:date]).to eq((empty_date).to_s)
        expect(json[:data]).to be_empty
      end
    end

    context "when params are empty" do
      it "defaults to most recent data" do
        get :all_for_date
        expect(json[:info][:date]).to eq((date2).to_s)
      end
    end
  end

  describe "#info" do
    let(:dates) { [(Date.yesterday - 1.month).to_s, Date.yesterday.to_s] }
    let(:lats) { [50.0, 55.0] }
    let(:longs) { [50.0, 55.0] }
    let(:ets) { [0.1, 0.2] }
    before(:each) do
      0.upto(1) do |i|
        FactoryBot.create(
          :evapotranspiration,
          latitude: lats[i],
          longitude: longs[i],
          date: dates[i],
          potential_et: ets[i]
        )
      end
    end

    it "is ok" do
      get :info
      expect(response).to have_http_status(:ok)
    end

    it "has the correct structure" do
      get :info
      expect(json.keys).to match([:date_range, :total_days, :lat_range, :long_range, :value_range])
    end

    it "returns data ranges for evapotranspiration" do
      get :info
      expect(json[:date_range]).to eq(dates)
      expect(json[:total_days]).to eq(dates.count)
      expect(json[:lat_range].map(&:to_i)).to eq(lats)
      expect(json[:long_range].map(&:to_i)).to eq(longs)
      expect(json[:value_range]).to eq(ets)
    end
  end

  describe "#calculate_et" do
    it "correctly formats the response" do
      get :calculate_et, params: {
        max_temp: 12.5,
        min_temp: 8.9,
        avg_temp: 10.7,
        vapor_p: 1.6,
        insol: 561,
        doy: 123,
        latitude: 43
      }

      expect(json.keys).to match([:inputs,:value])
    end
  end
end
