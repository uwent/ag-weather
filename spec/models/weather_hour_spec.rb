require "rails_helper"

RSpec.describe WeatherHour do
  let(:temp_key) { "2t" }
  let(:dew_point_key) { "2d" }
  let(:weather_hour) { WeatherHour.new }

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
    let(:lat) { Wisconsin.min_lat }
    let(:long) { Wisconsin.min_long }

    it "should add an element to the temperatures" do
      expect { weather_hour.store(lat, long, 17, temp_key) }
        .to change { weather_hour.data[lat, long][:temperatures].length }
        .by 1
    end

    it "should add an element to the dew points" do
      expect { weather_hour.store(lat, long, 17, dew_point_key) }
        .to change { weather_hour.data[lat, long][:dew_points].length }
        .by 1
    end

    it "won't store a nil value" do
      expect { weather_hour.store(lat, long, nil, temp_key) }
        .to change { weather_hour.data[lat, long][:temperatures].length }
        .by 0
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

    it "can handle an invalid data line" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name")
        .and_return([[], ["#{Wisconsin.min_lat} #{Wisconsin.min_long + 360.0}"], []]) # missing value and key
      weather_hour.load_from("file.name")
      expect(weather_hour.temperature_at(Wisconsin.min_lat, Wisconsin.min_long)).to be_nil
    end
  end

  # context "closest" do
  #   it "should find the closest value at point" do
  #     readings = [
  #       Reading.new(17.1, 17.1, 16),
  #       Reading.new(17.02, 17.02, 17),
  #       Reading.new(16.9, 17.2, 18),
  #       Reading.new(16.5, 17.0, 19),
  #       Reading.new(17.2, 17.2, 20)
  #     ]
  #     expect(weather_hour.closest(17.0, 17.0, readings)).to eq readings[1]
  #   end

  #   it "should return null if given empty array" do
  #     expect(weather_hour.closest(17.0, 17.0, [])).to be_nil
  #   end
  # end

  context "temperature_at" do
    let(:lat) { 45 }
    let(:long) { -85 }

    it "should return no value if no temperature stored at lat, long" do
      expect(weather_hour.temperature_at(lat, long)).to be_nil
    end

    it "should return average temperature at points within lat/long cell" do
      weather_hour.store(lat + 0.02, long, 1, temp_key)
      weather_hour.store(lat, long + 0.03, 2, temp_key)
      weather_hour.store(lat, long + 0.01, 3, temp_key)
      weather_hour.store(lat + 0.1, long + 0.1, 100, temp_key) # outside cell
      expect(weather_hour.temperature_at(lat, long)).to eq 2.0
    end
  end

  context "dew_point_at" do
    let(:lat) { 45 }
    let(:long) { -85 }

    it "should return no value if no dew point stored at lat, long" do
      expect(weather_hour.dew_point_at(lat, long)).to be_nil
    end

    it "should return average dew_point at points within lat/long cell" do
      weather_hour.store(lat + 0.03, long, 1, dew_point_key)
      weather_hour.store(lat, long - 0.04, 2, dew_point_key)
      weather_hour.store(lat + 0.01, long - 0.01, 3, dew_point_key)
      weather_hour.store(lat + 0.05, long - 0.1, 100, dew_point_key) # outside cell
      expect(weather_hour.dew_point_at(lat, long)).to eq 2.0
    end
  end
end
