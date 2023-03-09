require "rails_helper"

UNIT = "F"
UNIT2 = "C"

RSpec.describe DegreeDay do
  subject { DegreeDay }

  describe ".new_from_weather" do
    before do
      @weather = FactoryBot.build(:weather_datum)
      @new = subject.new_from_weather(@weather)
    end

    it { expect(@new).to be_valid }

    context "carries over values from weather" do
      %i[date latitude longitude].each do |col|
        it "uses #{col} value from weather" do
          expect(@new.send(col)).to_not be_nil
          expect(@new.send(col)).to eq @weather.send(col)
        end
      end
    end

    context "computes new values for degree day models" do
      DegreeDay.data_cols.each do |col|
        it "computes a valid value for #{col}" do
          expect(@new.send(col)).to_not be_nil
        end
      end
    end
  end

  describe ".default_col" do
    it { expect(subject.default_col).to_not be_nil }
    it { expect(subject.default_col).to be_an(Symbol) }
    it { expect(subject.default_col).to be_in(subject.data_cols) }
  end

  describe ".valid_units" do
    it { expect(subject.valid_units).to_not be_nil }
    it { expect(subject.valid_units).to be_an(Array) }
    it { expect(subject.valid_units[0]).to eq UNIT }
  end

  describe ".convert" do
    it "returns given value if units: #{UNIT}" do
      expect(subject.convert(value: 100, units: UNIT)).to eq 100
    end

    it "converts value if units: #{UNIT2}" do
      expect(subject.convert(value: 100, units: UNIT2)).to eq UnitConverter.fdd_to_cdd(100)
    end

    it "raises error on invalid units" do
      expect { subject.convert(value: 100, units: "foo") }.to raise_error(ArgumentError)
    end
  end

  describe ".parse_model" do
    context "when units: F" do
      units = "F"
      inputs = {
        dd_32: ["32", nil],
        dd_45_80p1: ["45", "80.1"],
        dd_50_86: ["50", "86"]
      }

      inputs.each do |col, parsed|
        it "should return #{parsed.inspect} when given #{col} and units: #{units}" do
          expect(subject.parse_model(col, units)).to eq parsed
        end
      end
    end

    context "when units: C" do
      units = "C"
      inputs = {
        dd_32: ["0", nil],
        dd_45_80p1: ["7.2", "26.7"],
        dd_50_86: ["10", "30"]
      }

      inputs.each do |col, parsed|
        it "should return #{parsed.inspect} when given #{col} and units: #{units}" do
          expect(subject.parse_model(col, units)).to eq parsed
        end
      end
    end
  end

  describe ".find_model" do
    context "when units: F" do
      # base, upper, units
      inputs = {
        [32, nil, "F"] => "dd_32",
        [45, 86, "F"] => "dd_45_86",
        [50.123, 86.78, "F"] => "dd_50p1_86p8"
      }

      inputs.each do |args, val|
        it "returns #{val} given base #{args[0].inspect}, upper #{args[1].inspect}, units #{args[2]}" do
          expect(subject.find_model(*args)).to eq val
        end
      end
    end

    context "when units: C" do
      # base, upper, units
      inputs = {
        [0, nil, "C"] => "dd_32",
        [7.2, 30, "C"] => "dd_45_86",
        [10.123, 30.78, "C"] => "dd_50p2_87p4"
      }

      inputs.each do |args, val|
        it "returns #{val} given base #{args[0].inspect}, upper #{args[1].inspect}, units #{args[2]}" do
          expect(subject.find_model(*args)).to eq val
        end
      end
    end
  end

  describe ".image_subdir" do
    it { expect(subject.image_subdir).to eq "degree_days" }
  end

  describe ".image_title" do
    let(:col) { subject.default_col }
    let(:start_date) { "2023-1-1".to_date }
    let(:date) { "2023-2-1".to_date }
    let(:units) { UNIT }
    let(:args) { {col:, date:, start_date:, end_date: date, units:} }

    it { expect(subject.image_title(**args)).to be_an(String) }

    it "should show units in title" do
      expect(subject.image_title(**args)).to include(UNIT)
      args[:units] = UNIT2
      expect(subject.image_title(**args)).to include(UNIT2)
    end

    it "should show degree day model name in title" do
      title = subject.image_title(**args)
      expect(title).to include("base 50")
    end

    it "should show degree day model in celsius" do
      args[:units] = UNIT2
      title = subject.image_title(**args)
      expect(title).to include("base 10")
    end

    context "when not given any date" do
      it { expect { subject.image_title }.to raise_error(ArgumentError) }
    end

    it "should include upper threshold" do
      args[:col] = :dd_50_86
      title = subject.image_title(**args)
      expect(title).to include("base 50°F, upper 86°F")
    end
  end
end
