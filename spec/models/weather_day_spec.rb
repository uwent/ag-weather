require "rails_helper"

RSpec.describe WeatherDay do
  let(:epsilon) { 1e-6 }
  let(:weather_day) { WeatherDay.new }

  context "initialization" do
    it "can be created" do
      expect(weather_day).not_to be_nil
    end
  end

  context "load from files" do
    it "should load weather hour for each file in passed directory" do
      allow(Dir).to receive(:[]).and_return(["foo/a.grb2", "foo/b.grb2"])
      allow_any_instance_of(WeatherHour).to receive(:load_from)
      expect(weather_day).to receive(:add_data_from_weather_hour).twice
      weather_day.load_from("foo")
    end
  end

  context "add data from a weather hour" do
    let(:wh) { WeatherHour.new }

    before do
      allow(wh).to receive(:temperature_at).and_return(20.0)
      allow(wh).to receive(:dew_point_at).and_return(20.0)
    end

    it "can add data from weather hour" do
      weather_day.add_data_from_weather_hour(wh)
    end
  end

  context "can access day's weather data" do
    let(:lat) { 45.0 }
    let(:long) { -89.0 }
    let(:wh1) { WeatherHour.new }
    let(:wh2) { WeatherHour.new }

    it "gets all temperatures at a latitude/longitude pair" do
      wh1.store(lat, long, 290.15, "2t") # should find
      wh1.store(lat + 1, long, 291.15, "2t") # should not find, wrong lat
      wh2.store(lat, long, 292.15, "2t") # should find
      wh2.store(lat, long, 293.15, "2d") # should not find, wrong key
      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)

      temps = weather_day.observations_at(lat, long).map(&:temperature)
      expect(temps).to contain_exactly(17.0, 19.0)
    end

    it "gets all dew points at a latitude/longitude pair" do
      wh1.store(lat, long, 274.15, "2d") # should find
      wh1.store(lat + 1, long, 276.15, "2d") # should not find, wrong lat
      wh2.store(lat, long, 275.15, "2d") # should find
      wh2.store(lat, long, 277.15, "2t") # should not find, wrong key
      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)

      dew_points = weather_day.observations_at(lat, long).map(&:dew_point)
      expect(dew_points).to contain_exactly(1.0, 2.0)
    end

    it "gets all humidities at a latitude/longitude pair" do
      wh1.store(lat, long, 280.0, "2t")
      wh1.store(lat, long, 280.0, "2d")
      wh2.store(lat, long, 290.0, "2t")
      wh2.store(lat, long, 280.0, "2d")
      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)

      humidities = weather_day.observations_at(lat, long).map(&:relative_humidity)
      expect(humidities.size).to eq(2)
      expect(humidities[0]).to eq(100.0)
      expect(humidities[1]).to be_within(epsilon).of(51.662830)
    end
  end
end
