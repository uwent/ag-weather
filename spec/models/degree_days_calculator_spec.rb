require "rails_helper"

# All resultant numbers have been pulled from UC-Davis degree calculator:
# http://www.ipm.ucdavis.edu/WEATHER/index.html
RSpec.describe DegreeDaysCalculator, type: :module do
  subject { DegreeDaysCalculator }
  let(:epsilon) { 0.000001 }

  describe ".calculate" do
    context "should delegate to proper method" do
      it "should delegate when 'average'" do
        expect(subject).to receive(:average_degree_days)
        subject.calculate(min: 10, max: 20, method: "average")
      end

      it "should delegate when 'modified'" do
        expect(subject).to receive(:modified_degree_days)
        subject.calculate(min: 10, max: 20, method: "modified")
      end

      it "should delegate when method is 'sine'" do
        expect(subject).to receive(:sine_degree_days)
        subject.calculate(min: 10, max: 20, method: "sine")
      end
    end

    context "when inputs invalid" do
      it "should raise an error on unknown method" do
        expect { subject.calculate(min: 10, max: 20, method: "foo") }.to raise_error(ArgumentError)
      end
    end

    context "when only min and max provided" do
      it "should select correct defaults" do
        expect(subject).to receive(:sine_degree_days).with(10, 50, subject::BASE_C, subject::UPPER_C)
        subject.calculate(min: 10, max: 50, method: "sine")
      end
    end
  end

  describe ".calculate_f" do
    it "should use Fahrenheit defaults and send args to .calculate" do
      expect(subject).to receive(:calculate).with({min: 38, max: 52, base: subject::BASE_F, upper: subject::UPPER_F, method: "sine"})
      subject.calculate_f(min: 38, max: 52)
    end
  end

  describe ".average_degree_days" do
    context "min and max < base" do
      it "should return 0.0" do
        expect(subject.average_degree_days(0, 25, 50)).to eq 0.0
      end
    end

    context "min or max > base" do
      it "should calculate correctly" do
        expect(subject.average_degree_days(-10, 80, 30)).to eq 5.0
        expect(subject.average_degree_days(48, 71, 50)).to eq 9.5
        expect(subject.average_degree_days(60, 90, 50)).to eq 25.0
      end
    end

    context "when invalid inputs" do
      it "should raise error when min > max" do
        expect {subject.average_degree_days(50, 20, 50)}.to raise_error(ArgumentError)
      end
    end
  end

  describe ".modified_degree_days" do
    context "min & max < base" do
      it "calculates correctly" do
        expect(subject.modified_degree_days(30, 39, 40, 90)).to eq 0.0
      end
    end

    context "min < base < max < upper" do
      it "calculates correctly" do
        expect(subject.modified_degree_days(30, 45, 40, 90)).to eq 2.5
      end
    end

    context "min < base < upper < max" do
      it "calculates correctly" do
        expect(described_class.modified_degree_days(38, 100, 40, 90)).to eq 25.0
      end
    end

    context "base < min < max < upper" do
      it "calculates correctly" do
        expect(described_class.modified_degree_days(47, 80, 40, 90)).to eq 23.5
      end
    end

    context "base < min < upper < max" do
      it "calculates correctly" do
        expect(described_class.modified_degree_days(63, 95, 40, 90)).to eq 36.5
      end
    end

    context "base < upper < min < max" do
      it "calculates correctly" do
        expect(described_class.modified_degree_days(90, 95, 40, 80)).to eq 40.0
      end
    end

    context "when invalid inputs" do
      it "should raise error when min > max" do
        expect {subject.modified_degree_days(50, 1, 1, 1)}.to raise_error(ArgumentError)
      end

      it "should raise error when base > upper" do
        expect {subject.modified_degree_days(1, 1, 50, 1)}.to raise_error(ArgumentError)
      end
    end
  end

  describe ".sine_degree_days" do
    context "min & max < base" do
      it "should return 0" do
        expect(subject.sine_degree_days(30, 35, 40, 90)).to eq 0.0
      end
    end

    context "min <  base < max < upper" do
      it "calculates correctly" do
        expect(subject.sine_degree_days(30, 45, 40, 90)).to be_within(epsilon).of(1.2712244)
      end
    end
    
    context "min <  base < upper < max" do
      it "calculates correctly" do
        expect(subject.sine_degree_days(38, 100, 40, 90)).to be_within(epsilon).of(27.419432)
      end
    end

    context "base < min < max < upper" do
      it "calculates correctly" do
        expect(subject.sine_degree_days(47, 80, 40, 90)).to eq 23.5
      end
    end

    context "base < min < upper < max" do
      it "calculates correctly" do
        expect(subject.sine_degree_days(63, 95, 40, 90)).to be_within(epsilon).of(38.1473627)
      end
    end

    context "base < upper < min < max" do
      it "calculates correctly" do
        expect(subject.sine_degree_days(90, 95, 40, 80)).to eq 40.0
      end
    end

    context "when invalid inputs" do
      it "should raise error when min > max" do
        expect {subject.sine_degree_days(50, 1, 1, 1)}.to raise_error(ArgumentError)
      end

      it "should raise error when base > upper" do
        expect {subject.sine_degree_days(1, 1, 50, 1)}.to raise_error(ArgumentError)
      end
    end
  end
end
