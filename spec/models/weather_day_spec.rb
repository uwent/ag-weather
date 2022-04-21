require "rails_helper"

RSpec.describe WeatherDay do
  let(:weather_day) { WeatherDay.new(Date.current) }
  # let (:times) {
  #   ((((Wisconsin.max_lat - Wisconsin.min_lat) / Wisconsin.step) + 1) *
  #   (((Wisconsin.max_long - Wisconsin.min_long) / Wisconsin.step) + 1))
  #   .round(0)
  # }
  # let (:times) { Wisconsin.num_points }

  context "initialization" do
    it "can be created" do
      expect(weather_day).not_to be_nil
    end
  end

  context "load from files" do
    it "should load weather hour for each file in passed directory" do
      skip "This doesn't work on a CircleCI"
      allow(Dir).to receive(:[]).and_return(["foo/a.grb2", "foo/b.grb2"])
      expect(weather_day).to receive(:add_data_from_weather_hour).twice
      weather_day.load_from("foo")
    end
  end

  context "add data from a weather hour" do
    let(:wh) { WeatherHour.new }

    it "gets temperature for each point from hour" do
      allow(wh).to receive(:dew_point_at).and_return(20.0)
      allow(wh).to receive(:temperature_at).and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end

    it "gets the dew point for each point from hour" do
      allow(wh).to receive(:temperature_at).and_return(20.0)
      allow(wh).to receive(:dew_point_at).and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end
  end

  context "can access day's weather data" do
    let(:lat) { Wisconsin.min_lat }
    let(:long) { Wisconsin.min_long }
    let(:wh1) { WeatherHour.new }
    let(:wh2) { WeatherHour.new }

    it "gets all temperatures at a latitude/longitude pair" do
      wh1.store(lat, long, 290.15, "2t") # should find
      wh1.store(lat + 1, long, 291.15, "2t") # should not find, wrong lat
      wh2.store(lat, long, 292.15, "2t") # should find
      wh2.store(lat, long, 293.15, "2d") # should not find, wrong key
      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      puts weather_day
      expect(weather_day.temperatures_at(lat, long)).to contain_exactly(17.0, 19.0)
    end

    it "gets all dew points at a latitude/longitude pair" do
      wh1.store(lat, long, 274.15, "2d") # should find
      wh1.store(lat + 1, long, 276.15, "2d") # should not find, wrong lat
      wh2.store(lat, long, 275.15, "2d") # should find
      wh2.store(lat, long, 277.15, "2t") # should not find, wrong key
      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)

      expect(weather_day.dew_points_at(lat, long)).to contain_exactly(1.0, 2.0)
    end
  end
end
