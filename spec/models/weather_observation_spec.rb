require "rails_helper"

RSpec.describe WeatherObservation do

  let (:weather_observation) { WeatherObservation.new(300.15, 290.15) }

  context "initialization" do
    it 'can be created' do
      expect(weather_observation).not_to be_nil
    end

    it 'will default the temperature to 0.0 if nil' do
      observation = WeatherObservation.new(nil, 290.0)
      expect(observation.temperature).to eq 0.0
    end

    it 'will default the dew point to 0.0 if nil' do
      observation = WeatherObservation.new(290.0, nil)
      expect(observation.dew_point).to eq 0.0
    end

    it 'will set temperature passed to celcius' do
      expect(weather_observation.temperature).to eq 27.0
    end

    it 'will set dew point passed to celcius' do
      expect(weather_observation.dew_point).to eq 17.0
    end
  end

  context 'relative humidity' do
    # Verified data via http://andrew.rsmas.miami.edu/bmcnoldy/Humidity.html
    it 'will compute correctly' do
      expect(weather_observation.relative_humidity).to be_within(0.01).of(54.33)

      observation = WeatherObservation.new(300.0, 300.0)
      expect(observation.relative_humidity).to eq 100.0

      observation = WeatherObservation.new(290.15, 300.15)
      expect(observation.relative_humidity).to be_within(0.01).of(184.05)

      observation = WeatherObservation.new(291.15, 290.15)
      expect(observation.relative_humidity).to be_within(0.01).of(93.88)
    end
  end

  describe '.K_to_C' do
    it "should return the proper value in Celcius" do
      expect(weather_observation.K_to_C(283.0)).to be_within(0.001).of(9.85)
    end
  end
end
