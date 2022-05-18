require "rails_helper"

RSpec.describe PestForecastsController, type: :controller do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:info) { json[:info] }
  let(:data) { json[:data] }
  let(:latest_date) { DataImport.latest_date }
  let(:earliest_date) { latest_date - 1.week }
  let(:empty_date) { "2000-01-01" }

  describe "#index" do
    let(:lats) { 49..50 }
    let(:longs) { -90..-89 }

    before(:each) do
      lats.each do |lat|
        longs.each do |long|
          (earliest_date..latest_date).each do |date|
            FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date:)
          end
        end
      end
    end

    context "when request is valid" do
      let(:params) {
        {
          pest: "potato_blight_dsv",
          start_date: earliest_date,
          end_date: latest_date
        }
      }

      it "is okay" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :index, params: params
        expect(json.keys).to match([:info, :data])
        expect(info).to be_an(Hash)
        expect(info.keys).to match([
          :pest,
          :start_date,
          :end_date,
          :lat_range,
          :long_range,
          :grid_points,
          :min_value,
          :max_value,
          :days_requested,
          :days_returned,
          :status,
          :compute_time
        ])
        expect(info[:status]).to eq("OK")
        expect(data).to be_an(Array)
        expect(data.first.keys).to match([
          :lat,
          :long,
          :total,
          :avg
        ])
      end

      it "has the correct number of elements" do
        get :index, params: params
        expect(data.size).to eq(lats.size * longs.size)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get :index, params: params
        expect(info[:start_date]).to eq(latest_date.beginning_of_year.to_s)
      end

      it "defaults end_date to most recent data" do
        params.delete(:end_date)
        get :index, params: params
        expect(info[:end_date]).to eq(latest_date.to_s)
      end

      it "can restrict lat range" do
        params[:lat_range] = "50,50"
        get :index, params: params
        expect(info[:lat_range]).to eq([50.0, 50.0])
        expect(data.size).to eq(longs.size)
      end

      it "can restrict long range" do
        params[:long_range] = "-90,-90"
        get :index, params: params
        expect(info[:long_range]).to eq([-90.0, -90.0])
        expect(data.size).to eq(lats.size)
      end

      it "can return a csv" do
        get :index, params: params, as: :csv
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("text/csv")
      end
    end

    context "when request is invalid" do
      let(:params) {
        {
          pest: "potato_blight_dsv",
          start_date: earliest_date,
          end_date: latest_date
        }
      }

      it "returns no data if no pest" do
        params.delete(:pest)
        get(:index, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("pest")
      end

      it "returns pest not found if invalid pest" do
        params.update({pest: "foo"})
        get(:index, params:)

        expect(info[:status]).to eq("pest not found")
        expect(data).to be_empty
      end

      it "returns no data when no data in date range" do
        params[:start_date] = Date.tomorrow
        params[:end_date] = Date.tomorrow
        get :index, params: params
        expect(info[:status]).to eq("no data")
        expect(data).to be_empty
      end

      it "rescues start_date to defaults" do
        params[:start_date] = "foo"
        get :index, params: params
        expect(info[:start_date]).to eq(latest_date.beginning_of_year.to_s)
      end

      it "rescues invalid end_date to default" do
        params[:end_date] = "foo"
        get :index, params: params
        expect(info[:end_date]).to eq(latest_date.to_s)
      end
    end
  end

  describe "#custom" do
    let(:lats) { 49..50 }
    let(:longs) { -90..-89 }

    context "if pest name given" do
      before(:each) do
        lats.each do |lat|
          longs.each do |long|
            earliest_date.upto(latest_date) do |date|
              FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date:)
            end
          end
        end
      end

      context "when request is valid" do
        let(:params) {
          {
            pest: "potato_blight_dsv",
            start_date: earliest_date,
            end_date: latest_date
          }
        }

        it "is ok" do
          get :custom, params: params
          expect(response).to have_http_status(:ok)
        end

        it "has the correct response structure" do
          get :custom, params: params
          expect(json.keys).to match([:info, :data])
          expect(info).to be_an(Hash)
          expect(info.keys).to match([
            :pest,
            :start_date,
            :end_date,
            :lat_range,
            :long_range,
            :grid_points,
            :min_value,
            :max_value,
            :days_requested,
            :days_returned,
            :status,
            :compute_time
          ])
          expect(info[:status]).to eq("OK")
          expect(data).to be_an(Array)
          expect(data.first.keys).to match([
            :lat,
            :long,
            :total
          ])
        end

        it "has the correct number of elements" do
          get :custom, params: params
          expect(data.size).to eq(lats.size * longs.size)
        end

        it "returns valid data" do
          get :custom, params: params
          expect(data.first[:lat]).to be_an(Numeric)
          expect(data.first[:long]).to be_an(Numeric)
          expect(data.first[:total]).to be_an(Numeric)
        end

        it "defaults start_date to beginning of year" do
          params.delete(:start_date)
          get :custom, params: params
          expect(info[:start_date]).to eq(latest_date.beginning_of_year.to_s)
        end

        it "defaults end_date to today" do
          params.delete(:end_date)
          get :custom, params: params
          expect(info[:end_date]).to eq(latest_date.to_s)
        end

        it "can restrict lat range" do
          params[:lat_range] = "50,50"
          get :custom, params: params
          expect(info[:lat_range]).to eq([50.0, 50.0])
          expect(data.size).to eq(longs.size)
        end

        it "can restrict long range" do
          params[:long_range] = "-90,-90"
          get :custom, params: params
          expect(info[:long_range]).to eq([-90.0, -90.0])
          expect(data.size).to eq(lats.size)
        end

        it "can return a csv" do
          get :custom, params: params, as: :csv
          expect(response).to have_http_status(:ok)
          expect(response.header["Content-Type"]).to include("text/csv")
        end
      end
    end

    context "if no pest name given" do
      before(:each) do
        lats.each do |lat|
          longs.each do |long|
            earliest_date.upto(latest_date) do |date|
              FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date:)
            end
          end
        end
      end

      context "when request is valid" do
        let(:params) {
          {
            start_date: earliest_date,
            end_date: latest_date
          }
        }

        it "is ok" do
          get :custom, params: params
          expect(response).to have_http_status(:ok)
        end

        it "has the correct response structure" do
          get :custom, params: params
          expect(json.keys).to match([:info, :data])
          expect(info).to be_an(Hash)
          expect(info.keys).to match([
            :pest,
            :start_date,
            :end_date,
            :lat_range,
            :long_range,
            :grid_points,
            :t_base,
            :t_upper,
            :units,
            :min_value,
            :max_value,
            :days_requested,
            :days_returned,
            :status,
            :compute_time
          ])
          expect(info[:status]).to eq("OK")
          expect(data).to be_an(Array)
          expect(data.first.keys).to match([:lat, :long, :total])
        end

        it "has the correct number of elements" do
          get :custom, params: params
          expect(data.size).to eq(lats.size * longs.size)
        end

        it "returns valid data" do
          get :custom, params: params
          expect(data.first[:lat]).to be_an(Numeric)
          expect(data.first[:long]).to be_an(Numeric)
          expect(data.first[:total]).to be_an(Numeric)
        end
      end
    end
  end

  describe "#point_details" do
    let(:lat) { 42.0 }
    let(:long) { -89.0 }

    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date:)
        FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date:)
      end
    end

    context "when request is valid" do
      let(:params) {
        {
          lat:,
          long:,
          start_date: earliest_date,
          end_date: latest_date,
          pest: "dd_50_86"
        }
      }

      it "is okay" do
        get :point_details, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :point_details, params: params
        expect(json.keys).to eq([:info, :data])
        expect(info).to be_an(Hash)
        expect(info.keys).to match([
          :pest,
          :lat,
          :long,
          :start_date,
          :end_date,
          :units,
          :cumulative_value,
          :days_requested,
          :days_returned,
          :status,
          :compute_time
        ])
        expect(info[:status]).to eq("OK")
        expect(data).to be_an(Array)
        expect(data.first.keys).to match([
          :date,
          :min_temp,
          :max_temp,
          :avg_temp,
          :avg_temp_hi_rh,
          :hours_hi_rh,
          :value,
          :cumulative_value
        ])
      end

      it "has the correct number of elements" do
        get :point_details, params: params
        expect(data.size).to eq((earliest_date..latest_date).count)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get :point_details, params: params
        expect(info[:start_date]).to eq(latest_date.beginning_of_year.to_s)
      end

      it "defaults end_date to today" do
        params.delete(:end_date)
        get :point_details, params: params
        expect(info[:end_date]).to eq(latest_date.to_s)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        lat = 43.015
        long = -89.49
        params.update({
          lat:,
          long:
        })
        get :point_details, params: params
        expect(info[:lat]).to eq(lat.round(1))
        expect(info[:long]).to eq(long.round(1))
      end

      it "can return a csv" do
        get :point_details, params: params, as: :csv
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
          end_date: latest_date,
          pest: "dd_50_86"
        }
      }

      it "and has no latitude return no data" do
        params.delete(:lat)
        get(:point_details, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("lat")
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get(:point_details, params:)

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("long")
      end
    end
  end

  describe "#custom_point_details" do
    let(:lat) { 42.0 }
    let(:long) { -89.0 }

    before(:each) do
      (earliest_date..latest_date).each do |date|
        FactoryBot.create(:weather_datum, latitude: lat, longitude: long, date:)
        FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date:)
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
        get :custom_point_details, params: params
        expect(response).to have_http_status(:ok)
      end

      it "has the correct response structure" do
        get :custom_point_details, params: params
        expect(info).to be_an(Hash)
        expect(info[:status]).to eq("OK")
        expect(data).to be_an(Array)
        expect(data.first.keys).to match([
          :date,
          :min_temp,
          :max_temp,
          :avg_temp,
          :value,
          :cumulative_value
        ])
      end

      it "has the correct number of elements" do
        get :custom_point_details, params: params
        expect(data.length).to eq((earliest_date..latest_date).count)
      end

      it "defaults start_date to beginning of year" do
        params.delete(:start_date)
        get :custom_point_details, params: params
        expect(info[:start_date]).to eq(latest_date.beginning_of_year.to_s)
      end

      it "defaults end_date to most recent data date" do
        params.delete(:end_date)
        get :custom_point_details, params: params
        expect(info[:end_date]).to eq(latest_date.to_s)
      end

      it "rounds lat and long to the nearest 0.1 degree" do
        lat = 43.015
        long = -89.49
        params.update({
          lat:,
          long:
        })
        get :custom_point_details, params: params
        expect(info[:lat]).to eq(lat.round(1))
        expect(info[:long]).to eq(long.round(1))
      end

      it "can return a csv" do
        get :custom_point_details, params: params, as: :csv
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

      it "and has no latitude raise error" do
        params.delete(:lat)
        get :custom_point_details, params: params

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("lat")
      end

      it "and has no longitude return no content" do
        params.delete(:long)
        get :custom_point_details, params: params

        expect(response).to have_http_status(:bad_request)
        expect(json[:error]).to match("long")
      end
    end
  end

  describe "#pvy" do
    let(:lat) { 42.0 }
    let(:long) { -89.0 }
    let(:params) { {lat:, long:} }

    before(:each) do
      FactoryBot.create(
        :pest_forecast,
        latitude: lat,
        longitude: long,
        date: Date.yesterday,
        dd_39p2_86: 1
      )
    end

    it "is okay" do
      get :pvy, params: params
      expect(response).to have_http_status(:ok)
    end

    it "has the correct response structure" do
      get :pvy, params: params
      expect(json.keys).to eq([
        :info,
        :current_dds,
        :future_dds,
        :data,
        :forecast
      ])
    end
  end

  describe "#freeze" do
    let(:lat) { 42.0 }
    let(:long) { -89.0 }
    let(:start_date) { Date.current - 2.weeks }
    let(:end_date) { Date.current - 1.week }

    before(:each) do
      start_date.upto(end_date) do |date|
        FactoryBot.create(:pest_forecast, latitude: lat, longitude: long, date:)
      end
    end
    let(:params) {
      {
        start_date:,
        end_date:
      }
    }

    it "is okay" do
      get :freeze, params: params
      expect(response).to have_http_status(:ok)
    end

    it "has the correct response structure" do
      get :freeze, params: params
      expect(json.keys).to match([:info, :data])
      expect(info).to be_an(Hash)
      expect(info.keys).to match([
        :start_date,
        :end_date,
        :lat_range,
        :long_range,
        :grid_points,
        :status,
        :compute_time
      ])
      expect(data).to be_an(Array)
      expect(data.first.keys).to match([
        :lat,
        :long,
        :freeze
      ])
    end
  end

  describe "#info" do
    it "is ok" do
      FactoryBot.create(:pest_forecast)
      get :info
      expect(response).to have_http_status(:ok)
    end
  end
end

private

def range_to_array(range)
  a = range.min
  b = range.max
  [a.to_s, b.to_s]
end
