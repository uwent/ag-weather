require "rails_helper"

# All resultant numbers have been pulled from UC-Davis degree calculator:
# http://www.ipm.ucdavis.edu/WEATHER/index.html
RSpec.describe DegreeDaysCalculator, type: :module do
  let(:epsilon) { 0.000001 }

  describe "converts between temperature units" do
    it "should convert celcius to fahrenheit" do
      expect(DegreeDaysCalculator.c_to_f(-40)).to eq(-40)
      expect(DegreeDaysCalculator.c_to_f(0)).to eq(32)
      expect(DegreeDaysCalculator.c_to_f(23.3)).to eq(73.94)
      expect(DegreeDaysCalculator.c_to_f(100)).to eq(212)
    end

    it "should convert fahrenheit to celcius" do
      expect(DegreeDaysCalculator.f_to_c(-40)).to eq(-40)
      expect(DegreeDaysCalculator.f_to_c(32)).to eq(0)
      expect(DegreeDaysCalculator.f_to_c(73.94)).to be_within(epsilon).of(23.3)
      expect(DegreeDaysCalculator.f_to_c(212)).to eq(100)
    end
  end

  describe "calculates degree days" do
    it "should calculate average degree days" do
      expect(DegreeDaysCalculator.average_degree_days(40, 49, 50)).to eq(0.0)
      expect(DegreeDaysCalculator.average_degree_days(48, 71, 50)).to eq(9.5)
      expect(DegreeDaysCalculator.average_degree_days(-10, 80, 30)).to eq(5.0)
      expect(DegreeDaysCalculator.average_degree_days(60, 90, 50)).to eq(25.0)
    end

    it "should calculate modified degree days" do
      # min < max < base < upper
      expect(DegreeDaysCalculator.modified_degree_days(30, 39, 40, 90)).to eq(0.0)
      # min <  base < max < upper
      expect(DegreeDaysCalculator.modified_degree_days(30, 45, 40, 90)).to eq(2.5)
      # min <  base < upper < max
      expect(DegreeDaysCalculator.modified_degree_days(38, 100, 40, 90)).to eq(25.0)
      # base < min < max < upper
      expect(DegreeDaysCalculator.modified_degree_days(47, 80, 40, 90)).to eq(23.5)
      # base < min < upper < max
      expect(DegreeDaysCalculator.modified_degree_days(63, 95, 40, 90)).to eq(36.5)
      # base < upper < min < max
      expect(DegreeDaysCalculator.modified_degree_days(90, 95, 40, 80)).to eq(40.0)
    end

    it "should calculate sine degree days" do
      # min < max < base < upper
      expect(DegreeDaysCalculator.sine_degree_days(30, 39, 40, 90)).to eq(0.0)
      # min <  base < max < upper
      expect(DegreeDaysCalculator.sine_degree_days(30, 45, 40, 90)).to be_within(epsilon).of(1.2712244)
      # min <  base < upper < max
      expect(DegreeDaysCalculator.sine_degree_days(38, 100, 40, 90)).to be_within(epsilon).of(27.419432)
      # base < min < max < upper
      expect(DegreeDaysCalculator.sine_degree_days(47, 80, 40, 90)).to eq(23.5)
      # base < min < upper < max
      expect(DegreeDaysCalculator.sine_degree_days(63, 95, 40, 90)).to be_within(epsilon).of(38.1473627)
      # base < upper < min < max
      expect(DegreeDaysCalculator.sine_degree_days(90, 95, 40, 80)).to eq(40.0)
    end
  end

  describe "calculate should delegate to proper method" do
    it "should delegate to when method is 'average'" do
      expect(DegreeDaysCalculator).to receive(:average_degree_days)
      DegreeDaysCalculator.calculate(10, 20, method: "average")
    end

    it "should delegate to when method is 'modified'" do
      expect(DegreeDaysCalculator).to receive(:modified_degree_days)
      DegreeDaysCalculator.calculate(10, 20, method: "modified")
    end

    it "should delegate to when method is 'sine'" do
      expect(DegreeDaysCalculator).to receive(:sine_degree_days)
      DegreeDaysCalculator.calculate(10, 20, method: "sine")
    end

    it "should raise an error on unknown method" do
      expect { DegreeDaysCalculator.calculate(10, 20, method: "foo") }.to raise_error(ArgumentError)
    end
  end
end
