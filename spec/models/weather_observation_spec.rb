require "rails_helper"

RSpec.describe WeatherObservation do
  subject { WeatherObservation }
  let(:epsilon) { 1e-6 }
 
  describe "initialization" do
    context "with good data" do
      let(:obs) { subject.new(300.15, 290.15) }

      it { expect(obs).to_not be_nil}

      # temps are in Kelvin in grib file
      it "will set temperature passed to celsius" do
        expect(obs.temperature).to eq 27.0
      end

      it "will set dew point passed to celsius" do
        expect(obs.dew_point).to eq 17.0
      end
    end

    context "with bad data" do
      it "will default the temperature to 0.0 if nil" do
        obs = subject.new(nil, 290.0)
        expect(obs.temperature).to eq 0.0
      end

      it "will default the dew point to 0.0 if nil" do
        obs = subject.new(290.0, nil)
        expect(obs.dew_point).to eq 0.0
      end
    end
  end

  # Verified data via https://bmcnoldy.rsmas.miami.edu/Humidity.html
  context "computes relative humidity" do
    inputs = {
      [300.15, 290.15] => 54.350247,
      [291.15, 290.15] => 93.882937,
      [300.0, 300.0] => 100,
    }

    inputs.each do |args, rh|
      t, td = args
      it "computes rh as #{rh} given temp #{t} and dewpoint #{td}" do
        obs = subject.new(t, td)
        expect(obs.relative_humidity).to be_within(epsilon).of rh
      end
    end
  end
end
