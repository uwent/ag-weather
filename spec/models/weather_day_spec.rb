require "rails_helper"

RSpec.describe WeatherDay do

  let (:weather_day) { WeatherDay.new(Date.current) }
  # let (:times) {
  #   ((((Wisconsin.max_lat - Wisconsin.min_lat) / Wisconsin.step) + 1) *
  #   (((Wisconsin.max_long - Wisconsin.min_long) / Wisconsin.step) + 1))
  #   .round(0)
  # }
  let (:times) { Wisconsin.num_points }

  context "initialization" do
    it "can be created" do
      expect(weather_day).not_to be_nil
    end
  end

  context "load from files" do
    it "should load weather hour for each file in passed directory" do
      allow(Dir).to receive(:[]).and_return(["foo/a.grb2", "foo/b.grb2"])
      expect(weather_day).to receive(:add_data_from_weather_hour).twice
      weather_day.load_from('foo')
    end
  end

  # TODO: Fix this
  context "add data from a weather hour", skip: "It returns one more value than it should!" do
    let(:wh) { WeatherHour.new }

    it 'gets temperature for each point from hour' do
      allow(wh).to receive(:dew_point_at).and_return(20.0)
      expect(wh).to receive(:temperature_at).exactly(times).times.and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end

    it 'gets the dew point for each point from hour' do
      allow(wh).to receive(:temperature_at).and_return(20.0)
      expect(wh).to receive(:dew_point_at).exactly(times).times.and_return(20.0)
      weather_day.add_data_from_weather_hour(wh)
    end
  end

  context "can access day's weather data" do
    let(:wh1) { WeatherHour.new }
    let(:wh2) { WeatherHour.new }

    it "gets all temperatures at a latitude/longitude pair" do
      wh1.store('2t', Wisconsin.min_lat, Wisconsin.min_long, 290.15) # should find
      wh1.store('2t', Wisconsin.max_lat, Wisconsin.min_long, 291.15) # should not find
      wh2.store('2t', Wisconsin.min_lat, Wisconsin.min_long, 292.15) # should find
      wh2.store('2d', Wisconsin.min_lat, Wisconsin.min_long, 293.15) # should not find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.temperatures_at(Wisconsin.min_lat, Wisconsin.min_long)).to contain_exactly(17.0, 19.0)
    end

    it "gets all dew points at a latitude/longitude pair" do
      wh1.store('2d', Wisconsin.min_lat, Wisconsin.min_long, 274.15) # should find
      wh1.store('2d', Wisconsin.max_lat, Wisconsin.min_long, 276.15) # should not find
      wh2.store('2t', Wisconsin.min_lat, Wisconsin.min_long, 277.15) # should not find
      wh2.store('2d', Wisconsin.min_lat, Wisconsin.min_long, 275.15) # should find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.dew_points_at(Wisconsin.min_lat, Wisconsin.min_long)).to contain_exactly(1.0, 2.0)
    end
  end

end
