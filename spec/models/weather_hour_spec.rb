require "rails_helper"

RSpec.describe WeatherHour do
  let(:temp_key) { "2t" }
  let(:dew_point_key) { "2d" }
  let(:weather_hour) { WeatherHour.new }
  let(:lat) { 45.0 }
  let(:long) { -89.0 }

  describe "initialization" do
    it "can be created" do
      expect(weather_hour).to_not be_nil
    end
  end

  describe ".data_key" do
    it "maps '2d' from grib file to dew_point_data" do
      expect(weather_hour.data_key(dew_point_key)).to eq :dew_points
    end
    it "maps '2t' from grib file to temperature_data" do
      expect(weather_hour.data_key(temp_key)).to eq :temperatures
    end
  end

  describe ".store" do
    context "with good data" do
      it "should add an element to the temperatures" do
        expect { weather_hour.store(lat, long, 17, temp_key) }
          .to change { weather_hour.data[[lat, long]][:temperatures].length }
          .by 1
      end

      it "should add an element to the dew points" do
        expect { weather_hour.store(lat, long, 17, dew_point_key) }
          .to change { weather_hour.data[[lat, long]][:dew_points].length }
          .by 1
      end

      it "rounds lat/long to 0.1 degree" do
        weather_hour.store(45.0, -89.1, 20, temp_key)
        weather_hour.store(45.01, -89.06, 25, temp_key)
        expect(weather_hour.data[[45.0, -89.1]][:temperatures]).to eq([20, 25])
      end
    end

    context "with bad data" do
      it "won't store a nil value" do
        expect { weather_hour.store(lat, long, nil, temp_key) }
          .to change { weather_hour.data[[lat, long]][:temperatures].length }
          .by 0
      end

      it "won't store a value outside extent" do
        weather_hour.store(0, 0, 1, temp_key)
        expect(weather_hour.data[[0, 0]]).to be_nil
      end

      it "ignores an unknown key" do
        weather_hour.store(45.0, -89.0, 1, :foo)
      end
    end
  end

  context ".load_from" do
    it "should call popen3" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], [], []])
      weather_hour.load_from("file.name")
    end

    it "should read data in range from popen3" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], ["#{lat} #{long + 360.0} 17.0 2t"], []])
      weather_hour.load_from("file.name")
      expect(weather_hour.temperature_at(lat, long)).to eq 17.0
    end

    it "can handle an invalid data line" do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name")
        .and_return([[], ["#{lat} #{long + 360.0}"], []]) # missing value and key
      weather_hour.load_from("file.name")
      expect(weather_hour.temperature_at(lat, long)).to be_nil
    end
  end

  context "temperature_at" do
    let(:lat) { 45.0 }
    let(:long) { -85.0 }

    it "should return no value if no temperature stored at lat, long" do
      expect(weather_hour.temperature_at(lat, long)).to be_nil
    end

    it "should store only valid data and return average temperature at points within lat/long cell" do
      weather_hour.store(lat + 0.01, long, 1, temp_key)
      weather_hour.store(lat, long, 2, temp_key)
      weather_hour.store(lat, long, 3, temp_key)
      weather_hour.store(lat + 0.1, long + 0.1, 100, temp_key) # outside cell
      weather_hour.store(0, 0, 100, temp_key) # outside extent
      expect(weather_hour.temperature_at(lat, long)).to eq 2.0
    end
  end

  context "dew_point_at" do
    let(:lat) { 45.0 }
    let(:long) { -85.0 }

    it "should return no value if no dew point stored at lat, long" do
      expect(weather_hour.dew_point_at(lat, long)).to be_nil
    end

    it "should store only valid data and return average dew_point at points within lat/long cell" do
      weather_hour.store(lat + 0.01, long, 1, dew_point_key)
      weather_hour.store(lat, long, 2, dew_point_key)
      weather_hour.store(lat, long, 3, dew_point_key)
      weather_hour.store(lat + 0.05, long - 0.1, 100, dew_point_key) # outside cell
      weather_hour.store(0, 0, 100, dew_point_key) # outside extent
      expect(weather_hour.dew_point_at(lat, long)).to eq 2.0
    end
  end
end
