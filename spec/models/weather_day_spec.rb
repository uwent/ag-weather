require "rails_helper"

RSpec.describe WeatherDay do

  let (:weather_day) { WeatherDay.new(Date.current) }

  context "initialization" do

    it "can be created" do
      expect(weather_day).not_to be_nil
    end
  end

  context "load from files" do
    it "should load whether hour for each file in passed directory" do
      allow(Dir).to receive(:[]).and_return(["foo/a.grb2", "foo/b.grb2"])
                                             
      expect(weather_day).to receive(:add_data_from_weather_hour).twice

      weather_day.load_from('foo')
    end
  end

  context "add data from a weather hour" do
    let(:wh) { WeatherHour.new } 
    
    it 'gets temperature for each point from hour' do
      times = (((WiMn::N_LAT - WiMn::S_LAT) / WiMn::STEP) + 1) *
         (((WiMn::W_LONG - WiMn::E_LONG) / WiMn::STEP) + 1)
       expect(wh).to receive(:temperature_at).exactly(times).times
       weather_day.add_data_from_weather_hour(wh)
     end

     it 'gets the dew point for each point from hour' do
       times = (((WiMn::N_LAT - WiMn::S_LAT) / WiMn::STEP) + 1) *
         (((WiMn::W_LONG - WiMn::E_LONG) / WiMn::STEP) + 1)
       expect(wh).to receive(:dew_point_at).exactly(times).times
       weather_day.add_data_from_weather_hour(wh)
     end
   end

  context "can access day's weather data" do
    let(:wh1) { WeatherHour.new }
    let(:wh2) { WeatherHour.new }

    it "gets all temperatures at a latitude/longitude pair" do
      wh1.store('2t', WiMn::S_LAT, WiMn::E_LONG, 17.0) # should find
      wh1.store('2t', WiMn::N_LAT, WiMn::E_LONG, 18.0) # should not find
      wh2.store('2t', WiMn::S_LAT, WiMn::E_LONG, 19.0) # should find
      wh2.store('2d', WiMn::S_LAT, WiMn::E_LONG, 20.0) # should not find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.temperatures_at(WiMn::S_LAT, WiMn::E_LONG)).to contain_exactly(17.0, 19.0)
    end

    it "gets all dew points at a latitude/longitude pair" do
      wh1.store('2d', WiMn::S_LAT, WiMn::E_LONG, 1.0) # should find
      wh1.store('2d', WiMn::N_LAT, WiMn::E_LONG, 3.0) # should not find
      wh2.store('2t', WiMn::S_LAT, WiMn::E_LONG, 4.0) # should not find
      wh2.store('2d', WiMn::S_LAT, WiMn::E_LONG, 2.0) # should find

      weather_day.add_data_from_weather_hour(wh1)
      weather_day.add_data_from_weather_hour(wh2)
      expect(weather_day.dew_points_at(WiMn::S_LAT, WiMn::E_LONG)).to contain_exactly(1.0, 2.0)
    end
  end

end
