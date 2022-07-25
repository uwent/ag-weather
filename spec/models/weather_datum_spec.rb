require "rails_helper"

RSpec.describe WeatherDatum, type: :model do
  describe ".calculate_all_degree_days_for_date_range" do
    it "calculates a degree day value for date range" do
      latitude = Wisconsin.min_lat
      longitude = Wisconsin.min_long
      key = [latitude, longitude]
      1.upto(10) { |i|
        FactoryBot.create(
          :weather_datum,
          date: Date.current - i.days,
          latitude:,
          longitude:
        )
      }

      grid = WeatherDatum.calculate_all_degree_days_for_date_range(
        lat_range: Wisconsin.latitudes,
        long_range: Wisconsin.longitudes,
        start_date: Date.current - 12.days,
        end_date: Date.current
      )

      expect(grid[key].round(1)).to eq 17.4
    end
  end

  describe "construct land grid with weather data for given date" do
    it "should constuct a land grid" do
      expect(WeatherDatum.land_grid_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it "should have weather data stored in the grid" do
      date = Date.current
      latitude = Wisconsin.max_lat
      longitude = Wisconsin.min_long
      FactoryBot.create(
        :weather_datum,
        date:,
        latitude:,
        longitude:
      )
      land_grid = WeatherDatum.land_grid_for_date(date)
      expect(land_grid[latitude, longitude]).to be_kind_of(WeatherDatum)
    end

    it "should store nil in grid for points without values" do
      land_grid = WeatherDatum.land_grid_for_date(Date.current)
      expect(land_grid[Wisconsin.max_lat, Wisconsin.max_long]).to be_nil
    end
  end

  describe "construct land grid with weather data since a given date" do
    it "should have arrays of weather data in the grid" do
      latitude = Wisconsin.max_lat
      longitude = Wisconsin.min_long
      1.upto(10) do |i|
        FactoryBot.create(
          :weather_datum,
          date: Date.current - i.days,
          latitude:,
          longitude:
        )
      end
      land_grid = WeatherDatum.land_grid_since(Date.current - 12.days)
      expect(land_grid[latitude, longitude]).to be_kind_of(Array)
      expect(land_grid[latitude, longitude].length).to eq 10
    end

    it "should store nil in grid for points without values" do
      land_grid = WeatherDatum.land_grid_since(10.days.ago)
      expect(land_grid[Wisconsin.max_lat, Wisconsin.min_long]).to be_nil
    end
  end

  describe "degree days" do
    it "should get degree days with its base/upper in Fahrenheit" do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0, max_temperature: 20.0)
      expect(DegreeDaysCalculator).to receive(:calculate)
        .with(
          UnitConverter.c_to_f(weather.min_temperature),
          UnitConverter.c_to_f(weather.max_temperature),
          base: 50, upper: 86, method: "sine"
        )
      weather.degree_days(50, 86, "sine")
    end

    it "should get degree days with its base/upper in Fahrenheit" do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0, max_temperature: 20.0)
      expect(weather.degree_days(50, 86, "sine")).to eq 7.834757752132984
    end

    it "should get degree days with its base/upper in Celsius" do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0, max_temperature: 20.0)
      expect(DegreeDaysCalculator).to receive(:calculate)
        .with(
          weather.min_temperature,
          weather.max_temperature,
          base: 10, upper: 30, method: "sine"
        )
      weather.degree_days(10, 30, "sine", false)
    end

    it "should get degree days with its base/upper in Celsius" do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0, max_temperature: 20.0)
      expect(weather.degree_days(10, 30, "sine", false)).to eq(4.352643195629435)
    end
  end

  describe "calculate all degree days" do
    it "should return a land grid" do
      expect(WeatherDatum.calculate_all_degree_days(Date.current)).to be_kind_of(LandGrid)
    end

    it "should call degree days for each point with data" do
      FactoryBot.create(:weather_datum, latitude: 42, longitude: -93, date: Date.yesterday)
      FactoryBot.create(:weather_datum, latitude: 45, longitude: -90, date: Date.yesterday)

      expect(DegreeDaysCalculator).to receive(:calculate).and_return(17).exactly(2).times
      WeatherDatum.calculate_all_degree_days(10.days.ago)
    end

    it "should call degree days for each point for each day of data" do
      FactoryBot.create(:weather_datum, date: Date.yesterday, latitude: 42, longitude: -93)
      FactoryBot.create(:weather_datum, date: 2.days.ago, latitude: 42, longitude: -93)

      expect(DegreeDaysCalculator).to receive(:calculate).and_return(17).exactly(2).times
      WeatherDatum.calculate_all_degree_days(10.days.ago)
    end
  end

  describe "create image for date" do
    let(:earliest_date) { Date.current - 1.weeks }
    let(:latest_date) { Date.current }
    let(:empty_date) { earliest_date - 1.week }
    let(:lat) { 45.0 }
    let(:long) { -89.0 }

    before(:each) do
      earliest_date.upto(latest_date) do |date|
        FactoryBot.create(:weather_datum, date:, latitude: lat, longitude: long, avg_temperature: 42.0)
        FactoryBot.create(:weather_data_import, readings_on: date)
      end
    end

    it "should call ImageCreator when data present" do
      expect(WeatherDatum).to receive(:create_image_data).exactly(1).times
      expect(ImageCreator).to receive(:create_image).exactly(1).times
      WeatherDatum.create_image(latest_date)
    end

    it "should construct a data grid and convert units" do
      weather = WeatherDatum.where(date: latest_date)
      grid_f = WeatherDatum.create_image_data(LandGrid.new, weather) # default units = F
      grid_c = WeatherDatum.create_image_data(LandGrid.new, weather, "C")
      expect(grid_f[lat, long].round(3)).to eq(UnitConverter.c_to_f(grid_c[lat, long]).round(3))
    end

    it "should return 'no_data.png' when data sources not loaded" do
      expect(WeatherDatum.create_image(empty_date)).to eq("no_data.png")
    end
  end
end
