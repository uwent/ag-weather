require "rails_helper"

RSpec.describe PestForecastsController, type: :controller do
  let(:json) { JSON.parse(response.body) }

  describe "#index" do
    let(:start_date) { Date.current - 2.weeks }
    let(:end_date) { Date.current - 1.week }
    let(:lats)  { 49..50 }
    let(:longs) { 89..90 }
    before(:each) do
      lats.each do |lat|
        longs.each do |long|
          (start_date..end_date).each do |date|
            FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date: date)
          end
        end
      end
    end

    context "when request is valid" do
      let(:params) {{
        pest: "potato_blight_dsv",
        start_date: start_date,
        end_date: end_date
      }}

      it "is okay" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :index, params: params
        expect(json.keys).to match(["status", "info", "data"])
        expect(json["status"]).to be_an(String)
        expect(json["info"]).to be_an(Hash)
        expect(json["data"]).to be_an(Array)
        expect(json["data"][0]).to include("lat", "long", "total", "avg", "freeze")
      end

      it "has the correct number of elements" do
        get :index, params: params
        expect(json["data"].size).to eq(lats.size * longs.size)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get :index, params: params
        expect(json["info"]["start_date"]).to eq(start_date.beginning_of_year.to_s)
      end

      it "defaults end_date to today" do
        params.delete(:end_date)
        get :index, params: params
        expect(json["info"]["end_date"]).to eq(Date.current.to_s)
      end

      it "can restrict lat range" do
        params["lat_range"] = "50,50"
        get :index, params: params
        expect(json["info"]["lat_range"]).to eq(["50.0", "50.0"])
        expect(json["data"].size).to eq(longs.size)
      end

      it "can restrict long range" do
        params["long_range"] = "90,90"
        get :index, params: params
        expect(json["info"]["long_range"]).to eq(["-90.0", "-90.0"])
        expect(json["data"].size).to eq(lats.size)
      end
    end

  end

  describe "#info" do
    let(:dates) { [1.week.ago.to_date.to_s, Date.yesterday.to_s] }
    let(:lats) { [50.0, 55.0] }
    let(:longs) { [50.0, 55.0] }
    let(:potato_blight_dsvs) { [1, 4] }
    before(:each) do
      0.upto(1) do |i|
        FactoryBot.create(
          :pest_forecast,
          latitude: lats[i],
          longitude: longs[i],
          date: dates[i],
          potato_blight_dsv: potato_blight_dsvs[i]
        )
      end
    end

    it "is ok" do
      get :info
      expect(response).to have_http_status(:ok)
    end

    it "has the correct structure" do
      get :info
      expect(json.keys).to match(["pest_names", "date_range", "days", "lat_range", "long_range", "params"])
    end

    it "returns data ranges for pest forecasts" do
      get :info
      expect(json["pest_names"]).to include("potato_blight_dsv")
      expect(json["date_range"]).to eq(dates)
      expect(json["days"]).to eq(dates.count)
      expect(json["lat_range"].map(&:to_i)).to eq(lats)
      expect(json["long_range"].map(&:to_i)).to eq(longs)
    end
  end

end
