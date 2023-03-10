require "rails_helper"

RSpec.describe EvapotranspirationsController, type: :controller do
  let(:data_class) { Evapotranspiration }
  let(:import_class) { EvapotranspirationDataImport }

  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:lat) { 45.0 }
  let(:long) { -89.0 }
  let(:latest_date) { Date.yesterday }
  let(:earliest_date) { latest_date - 1.week }
  let(:empty_date) { "2000-01-01" }

  describe "#index" do
    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:evapotranspiration, latitude: lat, longitude: long, date:)
        import_class.succeed(date)
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
        get(:index, params:)

        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:index, params:)

        expect(json[:data]).to be_an(Array)
        expect(json[:info]).to be_an(Hash)
        expect(json[:data][0].keys).to match([:date, :value, :cumulative_value])
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

      it "defaults end_date to latest date" do
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

      it "throws error on missing param: lat" do
        params.delete(:lat)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:message]).to eq "param is missing or the value is empty: lat"
      end

      it "throws error on missing param: long" do
        params.delete(:long)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:message]).to eq "param is missing or the value is empty: long"
      end
    end
  end

  describe "#map" do
    let(:date) { latest_date }
    let(:units) { "in" }
    let(:subdir) { data_class.image_subdir }

    before do
      allow(ImageCreator).to receive(:create_image)
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:evapotranspiration, date:, latitude: lat, longitude: long)
        import_class.succeed(date)
      end
    end

    context "when the request is valid" do
      it "is okay" do
        get(:map, params: {date:})
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:map, params: {date:})
        expect(json.keys).to eq([:info, :filename, :url])
      end

      it "responds with the correct map name if data loaded" do
        image_name = data_class.image_name(date:, units:)
        url = "/#{subdir}/#{image_name}"
        allow(ImageCreator).to receive(:create_image).and_return(image_name)

        get(:map, params: {date:})
        expect(json[:url]).to eq(url)
      end

      it "returns the correct image when given starting date" do
        start_date = date - 1.month
        image_name = data_class.image_name(date:, start_date:, units:)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)

        get(:map, params: {date:, start_date:})
        expect(json[:url]).to eq "/#{subdir}/#{image_name}"
      end

      it "responds to the units param" do
        units = "mm"
        image_name = data_class.image_name(date:, units:)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params: {date:, units:})


        expect(json[:url]).to eq "/#{subdir}/#{image_name}"
      end

      it "has the correct response of no map for date not loaded" do
        get(:map, params: {date: empty_date})

        expect(json[:url]).to be_nil
      end

      it "shows the image in the browser when format=png" do
        image_name = data_class.image_name(date:, units:)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params: {date:, format: :png})

        expect(response.body).to include("<img src=#{"/#{subdir}/#{image_name}"}")
      end
    end

    context "when the request is invalid" do
      it "returns error message on bad date" do
        get(:map, params: {date: "foo"})
        expect(json[:message]).to eq "Invalid date: 'foo'"
        expect(response.status).to eq 400
      end

      it "returns error message on bad units" do
        get(:map, params: {date:, units: "foo"})
        expect(json[:message]).to eq "Invalid unit 'foo'. Must be one of in, mm"
        expect(response.status).to eq 400
      end
    end
  end

  describe "#grid" do
    let(:date) { latest_date }
    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:evapotranspiration, date:)
        import_class.succeed(date)
      end
    end

    context "when the request is valid" do
      it "is okay" do
        get(:grid, params: {date:})

        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:grid, params: {date:})

        expect(json.keys).to match([:info, :data])
      end

      it "returns valid data" do
        get(:grid, params: {date:})

        puts json.inspect
        expect(json[:info]).to be_an(Hash)
        expect(json[:info][:status]).to eq("OK")
        expect(json[:data]).to be_an(Hash)
        expect(json[:data].keys.first).to eq :"[45.0, -89.0]"
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

        expect(json[:info][:date]).to eq(empty_date.to_s)
        expect(json[:data]).to be_empty
      end
    end

    context "when params are empty" do
      it "defaults to latest date" do
        get(:grid)

        expect(json[:info][:date]).to eq(latest_date.to_s)
      end
    end
  end

  describe "#info" do
    it "is ok" do
      FactoryBot.create(:evapotranspiration)
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
