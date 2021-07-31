require "rails_helper"

RSpec.describe WeatherDay do

  # before do
  #   allow(:WeatherExtent).to receive(:latitudes).and_return(0..10)
  #   allow(:WeatherExtent).to receive(:longitudes).and_return(0..10)
  # end
  # N = WeatherExtent::N_LAT
  # S = WeatherExtent::S_LAT
  # E = WeatherExtent::E_LONG
  # W = WeatherExtent::W_LONG
  # I = WeatherExtent::STEP
  N = WeatherExtent::N_LAT
  S = WeatherExtent::S_LAT
  E = WeatherExtent::E_LONG
  W = WeatherExtent::W_LONG
  I = WeatherExtent::STEP
  GRIDS = ((N - S) / I) * ((W - E) / I) + 1

  let (:weather_day) { WeatherDay.new(Date.current) }
  # let (:grids) { ((N - S) / I) * ((W - E) / I) + 3 }

  context "initialization" do
    it "can be created" do
      expect(weather_day).not_to be_nil
    end
  end

  context "load from files" do
    it "should load weather hour for each file in passed directory", skip: true do
      allow(Dir).to receive(:[]).and_return(["foo/a.grb2", "foo/b.grb2"])
      expect(weather_day).to receive(:add_data_from_weather_hour).twice
      weather_day.load_from('foo')
    end
  end

  context "add data from a weather hour" do
    let(:wh) { WeatherHour.new }

    it 'gets temperature for each point from hour' do
      allow(wh).to receive(:dew_point_at).and_return(20.0)
      expect(wh).to receive(:temperature_at).exactly(1).times.and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end

    it 'gets the dew point for each point from hour' do
      allow(wh).to receive(:temperature_at).and_return(20.0)
      expect(wh).to receive(:dew_point_at).exactly(1).times.and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end
  end

  context "can access day's weather data" do
    let(:wh1) { WeatherHour.new }
    let(:wh2) { WeatherHour.new }

    it "gets all temperatures at a latitude/longitude pair" do
      wh1.store('2t', S, E, 290.15) # should find
      wh1.store('2t', N, E, 291.15) # should not find
      wh2.store('2t', S, E, 292.15) # should find
      wh2.store('2d', S, E, 293.15) # should not find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.temperatures_at(S, E)).to contain_exactly(17.0, 19.0)
    end

    it "gets all dew points at a latitude/longitude pair" do
      wh1.store('2d', S, E, 274.15) # should find
      wh1.store('2d', N, E, 276.15) # should not find
      wh2.store('2t', S, E, 277.15) # should not find
      wh2.store('2d', S, E, 275.15) # should find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.dew_points_at(S, E)).to contain_exactly(1.0, 2.0)
    end
  end

end
