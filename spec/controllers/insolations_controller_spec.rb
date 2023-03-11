require "rails_helper"

RSpec.describe InsolationsController, type: :controller do
  let(:data_class) { Insolation }
  let(:import_class) { InsolationDataImport }

  let(:json) { JSON.parse(response.body) }
  let(:info) { json["info"] }
  let(:data) { json["data"] }

  let(:lat) { 45.0 }
  let(:long) { -89.0 }
  let(:end_date) { DataImport.latest_date }
  let(:start_date) { end_date - 1.week }
  let(:empty_date) { "2000-01-01" }

  describe "GET /index" do
    let(:params) { {lat:, long:, start_date:, end_date:} }

    before do
      start_date.upto(end_date) do |date|
        FactoryBot.create(:insolation, latitude: lat, longitude: long, date:)
        import_class.succeed(date)
      end
    end

    context "when request is valid" do
      it "is okay" do
        get(:index, params:)

        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:index, params:)

        expect(json.keys).to match_array(%w[info data])
        expect(info).to be_an Hash
        expect(data).to be_an Array
        expect(data.first.keys).to match(%w[date value cumulative_value])
      end

      it "has the correct number of elements" do
        get(:index, params:)

        expect(data.size).to eq((start_date..end_date).count)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get(:index, params:)

        expect(info["start_date"]).to eq(end_date.beginning_of_year.to_s)
      end

      it "defaults end_date to latest date" do
        params.delete(:end_date)
        get(:index, params:)

        expect(info["end_date"]).to eq(DataImport.latest_date.to_s)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        lat = 43.015
        long = -89.49
        params.update({lat:, long:})
        get(:index, params:)

        expect(info["lat"]).to eq(lat.round(1))
        expect(info["long"]).to eq(long.round(1))
      end

      it "can return a csv" do
        get(:index, params:, as: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when the request is invalid" do
      it "throws error on missing param: lat" do
        params.delete(:lat)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to eq "param is missing or the value is empty: lat"
      end

      it "throws error on missing param: long" do
        params.delete(:long)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to eq "param is missing or the value is empty: long"
      end
    end
  end

  describe "GET /map" do
    let(:date) { end_date }
    let(:url_base) { "/#{data_class.image_subdir}" }

    context "with no params" do
      before do
        allow(ImageCreator).to receive(:create_image).and_return("foo.png")
      end

      it "is ok" do
        expect(get(:map)).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:map)
        expect(json.keys).to eq(%w[info filename url])
      end
    end

    context "when creating a new image" do
      let(:units) { "mj" }

      it "returns the correct image for a single date" do
        params = {date:, units:}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns the correct image when given starting date" do
        start_date = end_date - 1.month
        params = {start_date:, end_date:, units:}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "responds to the units param" do
        units = "kwh"
        params = {date:, units:}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(image_name).to include("-kwh-")
        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns nil url when no data" do
        get(:map, params: {date: empty_date})

        expect(json["url"]).to be_nil
      end

      it "shows the image in the browser when format=png" do
        image_name = data_class.image_name(date:, units:)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params: {date:, format: :png})

        expect(response.body).to include("<img src=#{"#{url_base}/#{image_name}"}")
      end
    end

    context "when the request is invalid" do
      it "returns error message on bad date" do
        get(:map, params: {date: "foo"})

        expect(json["message"]).to eq "Invalid date: 'foo'"
        expect(response.status).to eq 400
      end

      it "returns error message on bad units" do
        get(:map, params: {date:, units: "foo"})

        expect(json["message"]).to eq "Invalid unit 'foo'. Must be one of MJ, KWh"
        expect(response.status).to eq 400
      end
    end
  end

  describe "GET /grid" do
    let(:date) { end_date }

    before do
      start_date.upto(end_date) do |date|
        FactoryBot.create(:insolation, date:)
        import_class.succeed(date)
      end
    end

    it "is okay" do
      get(:grid, params: {date:})

      expect(response).to have_http_status(:ok)
    end

    context "when params are empty" do
      it "defaults to latest date" do
        get(:grid)

        expect(info["date"]).to eq(end_date.to_s)
      end
    end

    context "when the request is valid" do
      it "has the correct response structure" do
        get(:grid, params: {date:})

        expect(json.keys).to match(%w[info data])
        expect(info).to be_an(Hash)
        expect(info["status"]).to eq("OK")
        expect(data).to be_an(Hash)
      end

      it "returns valid data" do
        get(:grid, params: {date:})

        expect(json["data"].keys.first).to eq "[45.0, -89.0]"
      end

      it "can return a csv" do
        get(:grid, params: {date:}, as: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when date is valid but has no data" do
      it "returns empty data" do
        get(:grid, params: {date: empty_date})

        expect(info["date"]).to eq(empty_date.to_s)
        expect(data).to be_empty
      end
    end
  end

  describe "GET /info" do
    it "is ok" do
      FactoryBot.create(:insolation)
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
