require "rails_helper"

UNIT = "mm"
UNIT2 = "in"

RSpec.describe Precip do
  subject { Precip }

  describe ".default_col" do
    it { expect(subject.default_col).to_not be_nil }
    it { expect(subject.default_col).to be_an(Symbol) }
    it { expect(subject.default_col).to be_in(subject.data_cols) }
  end

  describe ".valid_units" do
    it { expect(subject.valid_units).to_not be_nil }
    it { expect(subject.valid_units).to be_an(Array) }
  end

  describe ".convert" do
    it "returns given value if units: #{UNIT}" do
      expect(subject.convert(value: 1, units: "mm")).to eq 1
    end

    it "converts value if units: #{UNIT2}" do
      expect(subject.convert(value: 1, units: "in")).to eq UnitConverter.mm_to_in(1)
    end

    it "raises error on invalid units" do
      expect { subject.convert(value: 1, units: "foo") }.to raise_error(ArgumentError)
    end
  end

  describe ".image_subdir" do
    it { expect(subject.image_subdir).to eq "precip" }
  end

  describe ".image_title" do
    let(:start_date) { "2023-1-1".to_date }
    let(:date) { "2023-2-1".to_date }
    let(:units) { UNIT }
    let(:args) { {date:, start_date:, end_date: date, units:} }

    it { expect(subject.image_title(**args)).to be_an(String) }

    it "should show units in title" do
      expect(subject.image_title(**args)).to include(UNIT)
      args[:units] = UNIT2
      expect(subject.image_title(**args)).to include(UNIT2)
    end

    context "when given start_date" do
      it "should return string with start and end date" do
        expect(subject.image_title(**args)).to include("for Jan 1 - Feb 1, 2023")
      end
    end

    context "when not given start_date" do
      it "should return string with end date" do
        args.delete(:start_date)
        expect(subject.image_title(**args)).to include("for Feb 1, 2023")
      end
    end

    context "when start and end date are different years" do
      it "should show year for both dates" do
        args[:start_date] = "2022-1-1".to_date
        expect(subject.image_title(**args)).to include("for Jan 1, 2022 - Feb 1, 2023")
      end
    end

    context "when not given any date" do
      it { expect { subject.image_title }.to raise_error(ArgumentError) }
    end
  end
end
