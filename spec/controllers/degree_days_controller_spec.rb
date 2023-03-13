require "rails_helper"

RSpec.describe DegreeDaysController, type: :controller do
  let(:data_class) { DegreeDay }
  let(:import_class) { DegreeDayDataImport }
  let(:json) { JSON.parse(response.body) }
  let(:info) { json["info"] }
  let(:data) { json["data"] }

  let(:epsilon) { 1e-3 } # valid when responses are rounded to 4 digits
  let(:latest_date) { DataImport.latest_date }
  let(:end_date) { latest_date }
  let(:start_date) { end_date - 1.week }
  let(:dates) { start_date..end_date }
  let(:empty_date) { "2000-1-1".to_date }

  describe "GET /index" do
    let(:lat) { 45.0 }
    let(:long) { -89.0 }
    let(:params) { {lat:, long:} }

    # create point data
    before do
      dates.each do |date|
        FactoryBot.create(:weather_datum, date:, latitude: lat, longitude: long, min_temp: 10.0, max_temp: 30.0)
      end
    end

    context "when the request is valid" do
      context "with minimum params" do
        it "is okay" do
          get(:index, params:)

          expect(response).to have_http_status(:ok)
        end

        it "can return a csv" do
          get(:index, params:, as: :csv)

          expect(response).to have_http_status(:ok)
          expect(response.header["Content-Type"]).to include("text/csv")
        end

        it "has the correct response structure" do
          get(:index, params:)

          expect(json.keys).to eq(%w[info data])
          expect(info).to be_an Hash
          expect(data).to be_an Array
          expect(data.first.keys).to eq(%w[date min_temp max_temp avg_temp value cumulative_value])
        end

        it "uses appropriate default values for params" do
          get(:index, params:)

          expect(info["start_date"]).to eq(latest_date.beginning_of_year.to_s)
          expect(info["end_date"]).to eq(latest_date.to_s)
          expect(info["base"]).to eq("50")
          expect(info["method"]).to eq("sine")
          expect(info["units"]).to include "Fahrenheit"
        end

        it "returns valid data" do
          get(:index, params:)

          expect(data.size).to eq(dates.count)
          day = data.first
          expect(day["min_temp"]).to eq 50.0
          expect(day["max_temp"]).to eq 86.0
          expect(day["value"]).to eq 18.0
          expect(data.last.dig("cumulative_value")).to eq(18.0 * dates.count)
        end
      end

      context "with custom params" do
        it "responds to start date" do
          params[:start_date] = start_date
          get(:index, params:)

          expect(info["start_date"]).to eq(start_date.to_s)
        end

        it "responds to end date" do
          params[:end_date] = end_date - 1.day
          get(:index, params:)

          expect(info["end_date"]).to eq((end_date - 1.day).to_s)
        end

        it "responds to units param" do
          params[:units] = "C"
          get(:index, params:)

          expect(info["units"]).to include("Celsius")
          day = data.first
          expect(day["min_temp"]).to eq 10.0
          expect(day["max_temp"]).to eq 30.0
          expect(day["value"]).to eq 10.0
          expect(data.last.dig("cumulative_value")).to eq(10.0 * dates.count)
        end
      end

      context "it validates the request" do
        it "requires latitude param" do
          params.delete(:lat)
          get(:index, params:)

          expect(response).to have_http_status(:bad_request)
          expect(json["message"]).to match("lat")
        end

        it "gives error if latitude outside range" do
          get(:index, params: {lat: 10, long:})

          expect(json["message"]).to include("Invalid latitude")
        end

        it "requires longitude param" do
          params.delete(:long)
          get(:index, params:)

          expect(response).to have_http_status(:bad_request)
          expect(json["message"]).to match("long")
        end

        it "gives error if longitude outside range" do
          get(:index, params: {lat:, long: 10})

          expect(json["message"]).to include("Invalid longitude")
        end

        it "rounds lat and long to the nearest 0.1 degree" do
          get(:index, params: {lat: 45.123, long: -89.789})

          expect(info["lat"]).to eq(45.1)
          expect(info["long"]).to eq(-89.8)
          expect(data).to be_empty
        end

        it "gives error if invalid units" do
          params[:units] = "foo"
          get(:index, params:)

          expect(json["message"]).to include("Invalid unit")
        end

        it "gives error if invalid method" do
          params[:method] = "foo"
          get(:index, params:)

          expect(json["message"]).to include("Invalid method")
        end
      end
    end
  end

  describe "GET /dd_table" do
    let(:lat) { 45.0 }
    let(:long) { -89.0 }
    let(:params) {
      {lat:, long:, start_date:, end_date:, models: "dd_32,dd_50_86"}
    }

    # create point data
    before do
      dates.each do |date|
        FactoryBot.create(:weather_datum, date:, latitude: lat, longitude: long, min_temp: 10.0, max_temp: 30.0)
        FactoryBot.create(:degree_day, date:, latitude: lat, longitude: long, dd_32: 5.0, dd_50: 10.0, dd_50_86: 10.0)
      end
    end

    it "is okay" do
      get(:dd_table, params: {lat:, long:})

      expect(response).to have_http_status(:ok)
    end

    context "when the request is valid" do
      it "has the correct response structure" do
        get(:dd_table, params:)

        expect(json.keys).to eq(%w[info data])
        expect(info).to be_an(Hash)
        expect(data).to be_an(Hash)
        expect(data.keys).to include(start_date.to_s)
        expect(data[start_date.to_s].keys).to eq(%w[min_temp max_temp dd_32 dd_50_86])
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        params[:lat] = 45.123
        params[:long] = -89.789
        get(:dd_table, params:)

        expect(info["lat"]).to eq(45.1)
        expect(info["long"]).to eq(-89.8)
      end

      it "returns valid data when units are C" do
        get(:dd_table, params: params.merge(units: "C"))

        expect(info["units"]).to include("Celsius")
        first_data = data[start_date.to_s]
        last_data = data[end_date.to_s]
        expect(first_data["min_temp"]).to eq 10.0
        expect(first_data["max_temp"]).to eq 30.0
        expect(first_data["dd_32"]["value"]).to be_within(epsilon).of(2.7778)
        expect(first_data["dd_50_86"]["value"]).to be_within(epsilon).of(5.5556)
        expect(last_data["dd_32"]["total"]).to be_within(epsilon).of(2.7778 * dates.count)
        expect(last_data["dd_50_86"]["total"]).to be_within(epsilon).of(5.5556 * dates.count)
      end

      it "returns valid data when units are F" do
        get(:dd_table, params:)

        first_data = data[start_date.to_s]
        last_data = data[end_date.to_s]
        expect(info["units"]).to include("Fahrenheit")
        expect(first_data["min_temp"]).to eq 50.0
        expect(first_data["max_temp"]).to eq 86.0
        expect(first_data["dd_32"]["value"]).to eq 5.0
        expect(first_data["dd_50_86"]["value"]).to eq 10.0
        expect(last_data["dd_32"]["total"]).to eq(5.0 * dates.count)
        expect(last_data["dd_50_86"]["total"]).to eq(10.0 * dates.count)
      end

      it "uses dd_50_86 when no models provided" do
        params.delete(:models)
        get(:dd_table, params:)

        expect(info["models"]).to eq(["dd_50"])
      end
    end

    context "when the request is not valid" do
      it "raises error on missing lat param" do
        params.delete(:lat)
        get(:dd_table, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("lat")
      end

      it "raises error on missing long param" do
        params.delete(:long)
        get(:dd_table, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("long")
      end

      it "raises error on invalid models" do
        params[:models] = "foo,bar"
        get(:dd_table, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid models 'foo, bar'")
      end
    end
  end

  describe "GET /grid" do
    let(:latitudes) { [45.0, 45.1] }
    let(:longitudes) { [-89.1, -89.0] }
    let(:grid_points) { 4 }

    # create grid data
    before do
      dates.each do |date|
        latitudes.each do |latitude|
          longitudes.each do |longitude|
            FactoryBot.create(:degree_day, date:, latitude:, longitude:, dd_32: 5.0, dd_50: 10.0)
          end
        end
      end
    end

    context "with no params" do
      it "is ok" do
        get(:grid)

        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:grid)

        expect(json.keys).to eq(%w[info data])
        expect(info).to be_an Hash
        expect(data).to be_an Hash
      end

      it "uses appropriate defaults" do
        get(:grid)

        defaults = {
          "start_date" => latest_date.beginning_of_year.to_s,
          "end_date" => latest_date.to_s,
          "lat_range" => "38.0,50.0",
          "long_range" => "-98.0,-82.0",
          "model" => "base 50F",
          "units" => "Fahrenheit degree days"
        }
        defaults.each do |k, v|
          expect(info[k]).to eq(v)
        end
      end

      it "returns valid data" do
        get(:grid)

        expect(data.size).to eq(grid_points)
      end

      it "can return a csv" do
        get(:grid, as: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "with valid params" do
      it "can restrict lat range" do
        get(:grid, params: {lat_range: "45,45"})

        expect(info["lat_range"]).to eq("45.0,45.0")
        expect(data.size).to eq(longitudes.count)
      end

      it "can restrict long range" do
        get(:grid, params: {long_range: "-89,-89"})

        expect(info["long_range"]).to eq("-89.0,-89.0")
        expect(data.size).to eq(latitudes.count)
      end

      it "returns a specific degree day model" do
        get(:grid, params: {base: 32})

        expect(info["model"]).to eq("base 32F")
        expect(data.first[1]).to eq(10.0 * 4) # 4 days 10/day
      end

      it "returns a specific degree day model in C" do
        get(:grid, params: {base: 10, units: "C"})

        expect(info["model"]).to eq("base 10C")
        expect(data.first[1]).to eq(11.1111 * 4) # 4 days 10/day
      end
    end

    context "with invalid params" do
      it "rejects invalid latitude range" do
        get(:grid, params: {lat_range: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid latitude range 'foo'")
      end

      it "rejects invalid longitude range" do
        get(:grid, params: {long_range: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid longitude range 'foo'")
      end

      it "rejects latitude range outside of valid extents" do
        get(:grid, params: {lat_range: "1,100"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid latitude range '1,100'")
      end

      it "rejects longitude range outside of valid extents" do
        get(:grid, params: {long_range: "1,100"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid longitude range '1,100'")
      end

      it "rejects invalid units" do
        get(:grid, params: {units: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid unit 'foo'")
      end

      it "rejects invalid date" do
        get(:grid, params: {start_date: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid date 'foo'")
      end
    end
  end

  describe "GET /map" do
    let(:date) { end_date }
    let(:default_col) { DegreeDay.default_col }
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
      let(:units) { "f" }

      it "returns the correct image with default params" do
        params = {start_date:, end_date:, col: default_col, units:}
        image_name = data_class.image_name(**params)
        expect(image_name).to eq("degree-days-base-50-f-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}.png")
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns the correct image for a single date" do
        params = {date:, col: default_col, units:}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "responds to the units param" do
        units = "C"
        params = {date:, col: default_col, units:}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(image_name).to include("-c-")
        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns nil url when no data" do
        get(:map, params: {date: empty_date})

        expect(json["url"]).to be_nil
      end

      it "shows the image in the browser when format=png" do
        image_name = data_class.image_name(date:, col: "dd_50", units:)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params: {date:, format: :png})

        expect(response.body).to include("<img src=#{"#{url_base}/#{image_name}"}")
      end
    end

    context "when the request is invalid" do
      it "returns error message on bad date" do
        get(:map, params: {date: "foo"})

        expect(json["message"]).to eq "Invalid date 'foo'"
        expect(response.status).to eq 400
      end

      it "returns error message on bad units" do
        get(:map, params: {date:, units: "foo"})

        expect(json["message"]).to eq "Invalid unit 'foo'. Must be one of F, C"
        expect(response.status).to eq 400
      end
    end
  end

  describe "GET /info" do
    before do
      FactoryBot.create(:degree_day)
    end

    it "is ok" do
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
