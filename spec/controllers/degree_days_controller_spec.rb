require "rails_helper"

RSpec.describe DegreeDaysController, type: :controller do
  let(:data_class) { DegreeDay }
  let(:import_class) { DegreeDayDataImport }

  let(:json) { JSON.parse(response.body) }

  let(:lat) { 45.0 }
  let(:long) { -89.0 }
  let(:end_date) { DataImport.latest_date }
  let(:start_date) { end_date - 1.week }
  let(:dates) { start_date..end_date }
  let(:empty_date) { "2000-01-01" }

  describe "GET /index" do
    let(:params) { { lat:, long: } }

    before do
      dates.each do |date|
        FactoryBot.create(:weather_datum, date:, min_temp: 10.0, max_temp: 30.0)
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
          expect(json["info"]).to be_an Hash
          expect(json["data"]).to be_an Array
          expect(json["data"].first.keys).to eq(%w[date min_temp max_temp avg_temp value cumulative_value])
        end

        it "uses appropriate default values for params" do
          get(:index, params:)

          info = json["info"]
          expect(info["start_date"]).to eq(end_date.beginning_of_year.to_s)
          expect(info["end_date"]).to eq(end_date.to_s)
          expect(info["base"]).to eq("50")
          expect(info["method"]).to eq("sine")
          expect(info["units"]).to include "Fahrenheit"
        end

        it "returns valid data" do
          get(:index, params:)

          data = json["data"]
          expect(data.size).to eq(dates.count)
          expect(data.first.keys).to match_array(%w[date min_temp max_temp avg_temp value cumulative_value])
          day = data.first
          expect(day["min_temp"]).to eq 50.0
          expect(day["max_temp"]).to eq 86.0
          expect(day["value"]).to eq 18.0
          expect(json["data"].last.dig("cumulative_value")).to eq(18.0 * dates.count)
        end
      end

      context "with custom params" do
        it "responds to units param" do
          params[:units] = "C"
          get(:index, params:)

          expect(json["info"]["units"]).to include("Celsius")
          day = json["data"].first
          expect(day["min_temp"]).to eq 10.0
          expect(day["max_temp"]).to eq 30.0
          expect(day["value"]).to eq 10.0
          expect(json["data"].last.dig("cumulative_value")).to eq(10.0 * dates.count)
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
          lat = 45.123
          long = -89.789
          get(:index, params: {lat:, long:})

          expect(json["info"]["lat"]).to eq(lat.round(1))
          expect(json["info"]["long"]).to eq(long.round(1))
          expect(json["data"]).to be_empty
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
    let(:start_date) { "2022-01-01".to_date }
    let(:end_date) { "2022-01-04".to_date }
    let(:params) { { lat:, long:, start_date:, end_date:, models: "dd_32,dd_50_86" }
    }

    before do
      start_date.upto(end_date) do |date|
        FactoryBot.create(:weather_datum, date:, latitude: lat, longitude: long, min_temp: 10.0, max_temp: 30.0)
        FactoryBot.create(:degree_day, date:, latitude: lat, longitude: long, dd_32: 10, dd_50_86: 20)
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
        expect(json["info"]).to be_an(Hash)
        expect(json["data"]).to be_an(Hash)
        expect(json["data"].keys).to include(start_date.to_s)
        expect(json["data"][start_date.to_s].keys).to eq(%w[min_temp max_temp dd_32 dd_50_86])
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        get(:dd_table, params:)

        expect(json["info"]["lat"]).to eq(lat.round(1))
        expect(json["info"]["long"]).to eq(long.round(1))
      end

      it "returns valid data when units are C" do
        get(:dd_table, params: params.merge(units: "C"))

        expect(json["info"]["units"]).to include("Celsius")

        first_data = json["data"][start_date.to_s]
        last_data = json["data"][end_date.to_s]
        expect(first_data["min_temp"]).to eq 10.0
        expect(first_data["max_temp"]).to eq 30.0
        expect(first_data["dd_32"]["value"]).to eq 5.56
        expect(first_data["dd_50_86"]["value"]).to eq 11.11
        expect(last_data["dd_32"]["total"]).to eq 22.22
        expect(last_data["dd_50_86"]["total"]).to eq 44.44
      end

      it "returns valid data when units are F" do
        get(:dd_table, params:)

        first_data = json["data"][start_date.to_s]
        last_data = json["data"][end_date.to_s]
        expect(json["info"]["units"]).to include("Fahrenheit")
        expect(first_data["min_temp"]).to eq 50.0
        expect(first_data["max_temp"]).to eq 86.0
        expect(first_data["dd_32"]["value"]).to eq 10.0
        expect(first_data["dd_50_86"]["value"]).to eq 20.0
        expect(last_data["dd_32"]["total"]).to eq 40.0
        expect(last_data["dd_50_86"]["total"]).to eq 80.0
      end

      it "uses dd_50_86 when no models provided" do
        params.delete(:models)
        get(:dd_table, params:)

        expect(json["info"]["models"]).to eq(["dd_50_86"])
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

  describe "GET /info" do
    it "is ok" do
      FactoryBot.create(:weather_datum)
      get(:info)

      expect(response).to have_http_status(:ok)
    end
  end
end
