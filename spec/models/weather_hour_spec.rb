require "rails_helper"

RSpec.describe WeatherHour do
  let (:temp_key) { '2t' }
  let (:dew_point_key) { '2d' }
  let (:weather_hour) { WeatherHour.new }
  
  it 'has the grib tools available' do
    expect(system('grib_info')).to be(true)
  end
  
  context "initialization" do
    it "can be created" do
      expect(weather_hour).to_not be_nil
    end

    it "has temperature data" do
      expect(weather_hour.temp_data).to be_a_kind_of(LandGrid)
    end

    it "has dew point data" do
      expect(weather_hour.dew_point_data).to be_a_kind_of(LandGrid)
    end
  end

  context "grid for key" do
    it "maps '2d' from grib file to dew_point_data" do
      expect(weather_hour.grid_for_key(dew_point_key)).to eq weather_hour.dew_point_data
    end
    it "maps '2t' from grib file to dew_point_data" do
      expect(weather_hour.grid_for_key(temp_key)).to eq weather_hour.temp_data
    end
  end

  context "store" do
    it "should add an element to the temperature land grid" do
      expect { 
        weather_hour.store(temp_key, WiMn::N_LAT, WiMn::E_LONG, 17) 
      }.to change { 
        weather_hour.temp_data[WiMn::N_LAT, WiMn::E_LONG].length 
      }.by(1)
    end
    it "should add an element to the dew point land grid" do
      expect { 
        weather_hour.store(dew_point_key, WiMn::S_LAT, WiMn::W_LONG, 17) 
      }.to change { 
        weather_hour.dew_point_data[WiMn::S_LAT, WiMn::W_LONG].length 
      }.by(1)
    end
  end

  context "load" do
    it 'should call popen3' do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], [], []])
      weather_hour.load_from('file.name')
    end

    it 'should read data in range from popen3' do
      expect(Open3).to receive(:popen3).once.with("grib_get_data -w shortName=2t/2d -p shortName file.name").and_return([[], ["#{WiMn::S_LAT} #{360.0 - WiMn::E_LONG} 17.0 2t"], []])
      weather_hour.load_from('file.name')
      expect(weather_hour.temperature_at(WiMn::S_LAT, WiMn::E_LONG)).to eql 17.0
    end
  end

  context "closest" do
    it "should find the closest value at point" do
      readings = [ Reading.new(17.1, 17.1, 16),
                   Reading.new(17.02, 17.02, 17),
                   Reading.new(16.9, 17.2, 18),
                   Reading.new(16.5, 17.0, 19),
                   Reading.new(17.2, 17.2, 20)
                 ]
      expect(weather_hour.closest(17.0, 17.0, readings)).to eql readings[1]
    end

    it "should return null if given empty array" do
      expect(weather_hour.closest(17.0, 17.0, [])).to be_nil
    end
  end

  context "temperature_at" do
    it "should return no value if no temperature stored at lat, long" do
      expect(weather_hour.temperature_at(WiMn::N_LAT, WiMn::E_LONG)).to be_nil
    end
    
    it "should return temperature at closest lat, long " do
      weather_hour.store(temp_key, WiMn::S_LAT + 0.05, WiMn::W_LONG, 1) 
      weather_hour.store(temp_key, WiMn::S_LAT, WiMn::W_LONG + 0.05, 2) 
      weather_hour.store(temp_key, WiMn::S_LAT, WiMn::W_LONG + 0.01, 3) 
      weather_hour.store(temp_key, WiMn::S_LAT + 0.05, WiMn::W_LONG + 0.05, 4)
      expect(weather_hour.temperature_at(WiMn::S_LAT, WiMn::W_LONG)).to eql 3
    end
  end

  context "dew_point_at" do
    it "should return no value if no dew point stored at lat, long" do
      expect(weather_hour.dew_point_at(WiMn::N_LAT, WiMn::E_LONG)).to be_nil
    end

    it "should return dew_point at closest lat, long " do
      weather_hour.store(dew_point_key, WiMn::N_LAT + 0.05, WiMn::W_LONG, 1) 
      weather_hour.store(dew_point_key, WiMn::N_LAT, WiMn::W_LONG - 0.04, 2) 
      weather_hour.store(dew_point_key, WiMn::N_LAT + 0.01, WiMn::W_LONG - 0.01, 3) 
      expect(weather_hour.dew_point_at(WiMn::N_LAT, WiMn::W_LONG)).to eql 3
    end
  end
end


