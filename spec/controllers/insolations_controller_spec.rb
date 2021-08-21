require "rails_helper"

RSpec.describe InsolationsController, type: :controller do
  let(:json) { JSON.parse(response.body) }

  describe "#index" do
    let(:lat)  { 42.0 }
    let(:long) { 98.0 }
    before(:each) do
      1.upto(5) do |i|
        date = Date.current - i.days
        FactoryBot.create(
          :insolation,
          latitude: lat,
          longitude: long,
          date: date
        )
        InsolationDataImport.successful.create(readings_on: date)
      end
    end

    context "when request is valid" do
      let(:params) {{
        lat: lat,
        long: long,
        start_date: Date.current - 4.days,
        end_date: Date.current - 1.days,
      }}

      it "is okay" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :index, params: params
        expect(json).to be_an(Array)
        expect(json[0]).to include("date", "value")
      end

      it "has the correct number of elements" do
        get :index, params: params
        expect(json.length).to eq 4
      end

      it "defaults end_date to today" do
        params.delete(:end_date)
        get :index, params: params
        expect(json.length).to eq 4
      end
    end

    context "when the request is invalid" do
      let(:params) {{
        lat: lat,
        long: long,
        start_date: Date.current - 4.days,
        end_date: Date.current - 1.days
      }}

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

      it "and has no start_date return no content" do
        params.delete(:start_date)
        get :index, params: params
        expect(json).to be_empty
      end
    end
  end

  describe "#show" do
    context "when the request is valid" do
      let(:date) { "2016-01-06" }
      let(:filename) { "/insolation_20160106.png" }

      it "is okay" do
        get :show, params: { id: date }
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :show, params: { id: date }
        expect(json.keys).to eq(["map"])
      end

      it "responds with the correct map name if data loaded" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        InsolationDataImport.successful.create(readings_on: date)
        get :show, params: { id: date }
        expect(json["map"]).to eq filename
      end

      it "has the correct response of no map for date not loaded" do
        get :show, params: { id: date }
        expect(json["map"]).to eq "/no_data.png"
      end

      it "shows the image in the browser when format=png" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        InsolationDataImport.successful.create(readings_on: date)
        get :show, params: { id: date, format: :png }
        expect(response.body).to include("<img src=#{filename}")
      end
    end

    context "when the request is invalid" do
      let(:date) { Date.yesterday }
      let(:filename) { "/insolation_#{date.to_s(:number)}.png" }

      it "returns the most recent map" do
        allow(ImageCreator).to receive(:create_image).and_return(filename)
        InsolationDataImport.successful.create(readings_on: date)
        get :show, params: { id: "" }
        expect(json["map"]).to eq(filename)
      end
    end
  end

  describe "#all_for_date" do
    let(:date) { Date.parse("2020-06-01") }
    let(:lat) { 50.0 }
    let(:long) { 50.0 }
    before(:each) do
      0.upto(5) do |i|
        0.upto(5) do |j|
          FactoryBot.create(
            :insolation,
            latitude: lat + i,
            longitude: long + j,
            date: date,
            insolation: rand(100)
          )
        end
      end
      InsolationDataImport.successful.create(readings_on: date)
    end

    context "when the request is valid" do
      it "is okay" do
        get :all_for_date, params: { date: date }
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :all_for_date, params: { date: date }
        expect(json.keys).to match(["date", "status", "info", "data"])
      end

      it "returns valid data" do
        get :all_for_date, params: { date: date }
        expect(json["date"]).to eq(date.to_s)
        expect(json["status"]).to eq("OK")
        expect(json["data"]).to be_an(Array)
        expect(json["data"][0]).to include("lat", "long", "value")
      end
    end

    context "when date is valid but has no data" do
      it "returns empty data" do
        get :all_for_date, params: { date: date + 1.week }
        expect(json["date"]).to eq((date + 1.week).to_s)
        expect(json["data"]).to be_empty
      end
    end

    context "when params are empty" do
      it "defaults to most recent data" do
        InsolationDataImport.successful.create(readings_on: date + 1.day)
        get :all_for_date
        expect(json["date"]).to eq((date + 1.day).to_s)
        expect(json["status"]).to eq("no data")
        expect(json["data"]).to be_empty
      end
    end
  end

  describe "#info" do
    let(:dates) { [Date.today.to_s, Date.yesterday.to_s] }
    let(:lats) { [50.0, 55.0] }
    let(:longs) { [50.0, 55.0] }
    let(:insols) { [1, 100] }
    before(:each) do
      0.upto(1) do |i|
        FactoryBot.create(:insolation,
          latitude: lats[i],
          longitude: longs[i],
          date: dates[i],
          insolation: insols[i]
        )
      end
    end

    it "is ok" do
      get :info
      expect(response).to have_http_status(:ok)
    end

    it "has the correct structure" do
      get :info
      expect(json.keys).to match(["date_range", "lat_range", "long_range", "value_range"])
    end

    it "returns data ranges for insolation" do
      get :info
      expect(json["date_range"]).to eq(dates)
      expect(json["lat_range"].map(&:to_i)).to eq(lats)
      expect(json["long_range"].map(&:to_i)).to eq(longs)
      expect(json["value_range"]).to eq(insols)
    end
  end
end
