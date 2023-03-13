require "rails_helper"

RSpec.describe PestForecastsController, type: :controller do
  let(:data_class) { PestForecast }
  let(:import_class) { PestForecastDataImport }
  let(:json) { JSON.parse(response.body) }
  let(:info) { json["info"] }
  let(:data) { json["data"] }

  let(:lat) { 45.0 }
  let(:long) { -89.0 }
  let(:latest_date) { DataImport.latest_date }
  let(:end_date) { latest_date - 1.day }
  let(:start_date) { latest_date - 1.week }
  let(:dates) { start_date..latest_date }
  let(:empty_date) { "2000-1-1".to_date }
  let(:pest) { "potato_blight_dsv" }

  describe "GET /index" do
    let(:params) { {lat:, long:, pest:} }

    before do
      dates.each do |date|
        FactoryBot.create(:weather_datum, date:, min_temp: 10.0, max_temp: 30.0)
        FactoryBot.create(:pest_forecast, date:, potato_blight_dsv: 1)
      end
    end

    context "when request is valid" do
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
          expect(data.first.keys).to eq(%w[date min_temp max_temp avg_temp avg_temp_hi_rh hours_hi_rh value cumulative_value])
        end

        it "uses appropriate default values for params" do
          get(:index, params:)

          expect(info["start_date"]).to eq(latest_date.beginning_of_year.to_s)
          expect(info["end_date"]).to eq(latest_date.to_s)
          expect(info["units"]).to eq({"temp" => "F"})
        end

        it "returns valid data" do
          get(:index, params:)

          expect(data.size).to eq(dates.count)
          day = data.first
          expect(day["min_temp"]).to eq 50.0
          expect(day["max_temp"]).to eq 86.0
          expect(day["value"]).to eq 1.0
          expect(data.last.dig("cumulative_value")).to eq(dates.count)
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
          params[:units] = "c"
          get(:index, params:)

          expect(data.size).to eq(dates.count)
          day = data.first
          expect(day["min_temp"]).to eq 10.0
          expect(day["max_temp"]).to eq 30.0
        end
      end
    end

    context "when the request is invalid" do
      it "requires latitude param" do
        params.delete(:lat)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("lat")
      end

      it "requires longitude param" do
        params.delete(:long)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("long")
      end

      it "gives error if latitude outside range" do
        params[:lat] = 10
        get(:index, params:)

        expect(json["message"]).to include("Invalid latitude")
      end

      it "gives error if longitude outside range" do
        params[:long] = 10
        get(:index, params:)

        expect(json["message"]).to include("Invalid longitude")
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        params[:lat] = 45.123
        params[:long] = -89.789
        get(:index, params:)

        expect(info["lat"]).to eq(45.1)
        expect(info["long"]).to eq(-89.8)
        expect(data).to be_empty
      end

      it "gives error if invalid units" do
        params[:units] = "foo"
        get(:index, params:)

        expect(json["message"]).to include("Invalid unit")
      end

      it "gives error if invalid pest" do
        params[:pest] = "foo"
        get(:index, params:)

        expect(json["message"]).to include("Invalid pest")
      end
    end
  end

  describe "GET /pvy" do
    let(:lat) { 45.0 }
    let(:long) { -89.0 }
    let(:params) { {lat:, long:} }

    before do
      FactoryBot.create(:degree_day, date: latest_date, latitude: lat, longitude: long, dd_39p2_86: 1)
    end

    it "is okay" do
      get(:pvy, params:)

      expect(response).to have_http_status(:ok)
    end

    it "has the correct response structure" do
      get(:pvy, params:)

      expect(json.keys).to eq(%w[info current_dds future_dds data forecast])
    end
  end

  describe "GET /grid" do
    let(:latitudes) { [45.0, 45.1] }
    let(:longitudes) { [-89.1, -89.0] }
    let(:grid_points) { 4 }
    let(:params) { {pest:} }

    # create grid data
    before do
      dates.each do |date|
        latitudes.each do |latitude|
          longitudes.each do |longitude|
            FactoryBot.create(:pest_forecast, date:, latitude:, longitude:, potato_blight_dsv: 1, potato_p_days: 5.0)
          end
        end
      end
    end

    context "with minimum params" do
      it "is ok" do
        get(:grid, params:)

        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get(:grid, params:)

        expect(json.keys).to eq(%w[info data])
        expect(info).to be_an Hash
        expect(data).to be_an Hash
      end

      it "uses appropriate defaults" do
        get(:grid, params:)

        defaults = {
          "start_date" => latest_date.beginning_of_year.to_s,
          "end_date" => latest_date.to_s,
          "lat_range" => "38.0,50.0",
          "long_range" => "-98.0,-82.0"
        }
        defaults.each do |k, v|
          expect(info[k]).to eq(v)
        end
      end

      it "returns valid data" do
        get(:grid, params:)

        expect(data.size).to eq(grid_points)
      end

      it "can return a csv" do
        get(:grid, params:, as: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "with valid params" do
      it "can restrict lat range" do
        params[:lat_range] = "45,45"
        get(:grid, params:)

        expect(info["lat_range"]).to eq("45.0,45.0")
        expect(data.size).to eq(longitudes.count)
      end

      it "can restrict long range" do
        params[:long_range] = "-89,-89"
        get(:grid, params:)

        expect(info["long_range"]).to eq("-89.0,-89.0")
        expect(data.size).to eq(latitudes.count)
      end

      it "can give a different pest model" do
        params[:pest] = "potato_p_days"
        get(:grid, params:)

        expect(data["[45.0, -89.0]"]).to eq({
          "avg" => 5.0,
          "total" => 5.0 * 8
        })
      end
    end

    context "with invalid params" do
      it "rejects invalid latitude range" do
        params[:lat_range] = "foo"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid latitude range 'foo'")
      end

      it "rejects invalid longitude range" do
        params[:long_range] = "foo"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid longitude range 'foo'")
      end

      it "rejects latitude range outside of valid extents" do
        params[:lat_range] = "1,100"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid latitude range '1,100'")
      end

      it "rejects longitude range outside of valid extents" do
        params[:long_range] = "1,100"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid longitude range '1,100'")
      end

      it "rejects invalid date" do
        params[:start_date] = "foo"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid date 'foo'")
      end

      it "rejects invalid pest" do
        params[:pest] = "foo"
        get(:grid, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid pest name 'foo'")
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
      it "returns the correct image with default params" do
        params = {start_date:, end_date:, col: pest}
        image_name = data_class.image_name(**params)
        expect(image_name).to eq("late-blight-dsv-#{start_date.to_formatted_s(:number)}-#{end_date.to_formatted_s(:number)}.png")
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns the correct image for a single date" do
        params = {date:, col: pest}
        image_name = data_class.image_name(**params)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params:)

        expect(json["url"]).to eq "#{url_base}/#{image_name}"
      end

      it "returns nil url when no data" do
        get(:map, params: {date: empty_date})

        expect(json["url"]).to be_nil
      end

      it "shows the image in the browser when format=png" do
        image_name = data_class.image_name(date:, col: pest)
        allow(ImageCreator).to receive(:create_image).and_return(image_name)
        get(:map, params: {date:, format: :png})

        expect(response.body).to include("<img src=#{"#{url_base}/#{image_name}"}")
      end
    end

    context "when the request is invalid" do
      it "returns error message on bad date" do
        get(:map, params: {date: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to eq("Invalid date 'foo'")
      end

      it "returns error message on bad pest" do
        get(:map, params: {date:, pest: "foo"})

        expect(response).to have_http_status(:bad_request)
        expect(json["message"]).to match("Invalid pest name 'foo'")
      end
    end
  end

  describe "GET /info" do
    it "is ok" do
      FactoryBot.create(:pest_forecast)
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
