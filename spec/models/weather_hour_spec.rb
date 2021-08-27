require "rails_helper"

RSpec.describe WeatherHour do
  let (:temp_key) { "2t" }
  let (:dew_point_key) { "2d" }
  let (:weather_hour) { WeatherHour.new }

  # grib on staging/production is grib_info, 
  it "has the grib tools available" do
    expect(system("codes_info > /dev/null")).to be(true)
    skip("This test doesn't work on CI")
  end

  context "initialization" do
    it "can be created" do
      expect(weather_hour).to_not be_nil
    end
  end

  context "data key" do
    it "maps '2d' from grib file to dew_point_data" do
      expect(weather_hour.data_key(dew_point_key)).to eq :dew_points
    end
    it "maps '2t' from grib file to temperature_data" do
      expect(weather_hour.data_key(temp_key)).to eq :temperatures
    end
  end

  context "store" do
    it "should add an element to the temperatures" do
      expect {
        weather_hour.store(temp_key, Wisconsin.min_lat, Wisconsin.min_long, 17)
      }.to change {
        weather_hour.data[Wisconsin.min_lat, Wisconsin.min_long][:temperatures].length
      }.by(1)
    end
    it "should add an element to the dew points" do
      expect {
        weather_hour.store(dew_point_key, Wisconsin.min_lat, Wisconsin.min_long, 17)
      }.to change {
        weather_hour.data[Wisconsin.min_lat, Wisconsin.min_long][:dew_points].length
      }.by(1)
    end
  end

  context "load" do
    it "should call popen3" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], [], []])
      weather_hour.load_from("file.name")
    end

    it "should read data in range from popen3" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], ["#{Wisconsin.min_lat} #{Wisconsin.min_long + 360.0} 17.0 2t"], []])
      weather_hour.load_from("file.name")
      expect(weather_hour.temperature_at(Wisconsin.min_lat, Wisconsin.min_long)).to eq 17.0
    end
  end

  context "closest" do
    it "should find the closest value at point" do
      readings = [
        Reading.new(17.1, 17.1, 16),
        Reading.new(17.02, 17.02, 17),
        Reading.new(16.9, 17.2, 18),
        Reading.new(16.5, 17.0, 19),
        Reading.new(17.2, 17.2, 20)
      ]
      expect(weather_hour.closest(17.0, 17.0, readings)).to eq readings[1]
    end

    it "should return null if given empty array" do
      expect(weather_hour.closest(17.0, 17.0, [])).to be_nil
    end
  end

  context "temperature_at" do
    it "should return no value if no temperature stored at lat, long" do
      expect(weather_hour.temperature_at(Wisconsin.max_lat, Wisconsin.min_long)).to be_nil
    end

    it "should return temperature at closest lat, long " do
      weather_hour.store(temp_key, Wisconsin.min_lat + 0.05, Wisconsin.max_long, 1)
      weather_hour.store(temp_key, Wisconsin.min_lat, Wisconsin.max_long + 0.05, 2)
      weather_hour.store(temp_key, Wisconsin.min_lat, Wisconsin.max_long + 0.01, 3)
      weather_hour.store(temp_key, Wisconsin.min_lat + 0.05, Wisconsin.max_long + 0.05, 4)
      expect(weather_hour.temperature_at(Wisconsin.min_lat, Wisconsin.max_long)).to eq(3)
    end
  end

  context "dew_point_at" do
    it "should return no value if no dew point stored at lat, long" do
      expect(weather_hour.dew_point_at(Wisconsin.max_lat, Wisconsin.min_long)).to be_nil
    end

    it "should return dew_point at closest lat, long" do
      weather_hour.store(dew_point_key, Wisconsin.max_lat + 0.05, Wisconsin.max_long, 1)
      weather_hour.store(dew_point_key, Wisconsin.max_lat, Wisconsin.max_long - 0.04, 2)
      weather_hour.store(dew_point_key, Wisconsin.max_lat + 0.01, Wisconsin.max_long - 0.01, 3)
      expect(weather_hour.dew_point_at(Wisconsin.max_lat, Wisconsin.max_long)).to eq(3)
    end
  end
end
