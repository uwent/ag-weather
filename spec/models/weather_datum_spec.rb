require "rails_helper"

RSpec.describe WeatherDatum, type: :model do

  describe "#land_grid_for_date_range" do
    it 'creates a land grid in date range' do
      latitude = Wisconsin::N_LAT
      longitude = Wisconsin::E_LONG
      1.upto(10) { |i| FactoryGirl.create(
        :weather_datum,
        date: Date.current - i.days,
        latitude: latitude,
        longitude: longitude
      )}
      land_grid = WeatherDatum.land_grid_for_date_range(Date.current - 12.days, Date.current)
      expect(land_grid[latitude, longitude]).to be_kind_of(Array)
      expect(land_grid[latitude, longitude].length).to eq 10

      land_grid = WeatherDatum.land_grid_for_date_range(Date.current - 60.days, Date.current - 40.days)
      expect(land_grid[latitude, longitude]).to eq nil
    end
  end

  describe "#calculate_all_degree_days_for_date_range" do
    it 'calculates a degree day value for date range' do
      latitude = Wisconsin::N_LAT
      longitude = Wisconsin::E_LONG
      1.upto(10) { |i| FactoryGirl.create(
        :weather_datum,
        date: Date.current - i.days,
        latitude: latitude,
        longitude: longitude
      )}

      grid = WeatherDatum.calculate_all_degree_days_for_date_range(
        'sine',
        Date.current - 12.days,
        Date.current)

      expect(grid[latitude, longitude].round(1)).to eq 17.4
    end
  end

  describe "construct land grid with weather data for given date" do
    it 'should constuct a land grid' do
      expect(WeatherDatum.land_grid_for_date(Date.current)).to be_kind_of(LandGrid)
    end

    it 'should have weather data stored in the grid' do
      date = Date.current
      latitude = Wisconsin::N_LAT
      longitude = Wisconsin::E_LONG
      FactoryBot.create(:weather_datum, date: date, latitude: latitude,
                         longitude: longitude)
      land_grid = WeatherDatum.land_grid_for_date(date)
      expect(land_grid[latitude, longitude]).to be_kind_of(WeatherDatum)
    end

    it 'should store nil in grid for points without values' do
      land_grid = WeatherDatum.land_grid_for_date(Date.current)
      expect(land_grid[Wisconsin::N_LAT, Wisconsin::E_LONG]).to be_nil
    end
  end

  describe "construct land grid with weather data since a given date" do
    it 'should have arrays of weather data in the grid' do
      latitude = Wisconsin::N_LAT
      longitude = Wisconsin::E_LONG
      1.upto(10) do |i|
        FactoryBot.create(:weather_datum, date: Date.current - i.days,
                           latitude: latitude, longitude: longitude)
      end
      land_grid = WeatherDatum.land_grid_since(Date.current - 12.days)
      expect(land_grid[latitude, longitude]).to be_kind_of(Array)
      expect(land_grid[latitude, longitude].length).to eq 10
    end

    it 'should store nil in grid for points without values' do
      land_grid = WeatherDatum.land_grid_since(10.days.ago)
      expect(land_grid[Wisconsin::N_LAT, Wisconsin::E_LONG]).to be_nil
    end
  end

  describe "degree days" do
    it 'should get degree days with its min and max temps in Fahrenheit' do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0,
                                   max_temperature: 20.0)
      expect(DegreeDaysCalculator).to receive(:calculate)
        .with("sine",
              DegreeDaysCalculator.to_fahrenheit(weather.min_temperature),
              DegreeDaysCalculator.to_fahrenheit(weather.max_temperature),
              50, 86)
      weather.degree_days("sine", 50, 86)
    end
    it 'should get degree days with its min and max temps in Fahrenheit' do
      weather = FactoryBot.create(:weather_datum, min_temperature: 8.0,
                                   max_temperature: 20.0)
      expect(weather.degree_days("sine", 50, 86)).to eq 7.834757752132984
    end
  end


  describe "calculate all degree days" do
    it 'should return a land grid' do
      expect(WeatherDatum.calculate_all_degree_days("sine", Date.current)).to be_kind_of(LandGrid)
    end

    it 'should call degree days for each point with data' do
      FactoryBot.create(:weather_datum, latitude: 42, longitude: 93)
      FactoryBot.create(:weather_datum, latitude: 43, longitude: 93)
      expect(DegreeDaysCalculator).to receive(:calculate).exactly(2).times

      WeatherDatum.calculate_all_degree_days("sine", 10.days.ago)
    end

    it 'should call degree days for each point for each day of data' do
      FactoryBot.create(:weather_datum, latitude: 42, longitude: 93,
                         date: Date.yesterday)
      FactoryBot.create(:weather_datum, latitude: 42, longitude: 93,
                         date: 2.days.ago)
      expect(DegreeDaysCalculator).to receive(:calculate).and_return(17).exactly(2).times

      WeatherDatum.calculate_all_degree_days("sine", 10.days.ago)
    end
  end
end
