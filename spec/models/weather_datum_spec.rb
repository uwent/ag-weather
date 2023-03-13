require "rails_helper"

RSpec.describe WeatherDatum do
  subject { WeatherDatum }
  unit1 = "C"
  unit2 = "F"

  describe "static configurations" do
    describe ".default_col" do
      it { expect(subject.default_col).to be_in(subject.data_cols) }
    end

    describe ".default_stat" do
      it { expect(subject.default_stat).to be_in(subject.valid_stats) }
    end

    describe ".image_subdir" do
      it { expect(subject.image_subdir).to eq "weather" }
    end

    describe ".col_attr" do
      it { expect(subject.col_attr).to be_an(Hash) }
      it { expect(subject.col_attr.keys).to match_array(subject.data_cols) }
    end
  end

  describe "dynamic configurations" do
    describe ".col_name" do
      it "gets the title for a given column" do
        expect(subject.col_name(:max_temp)).to eq "Max air temp"
        expect(subject.col_name(:vapor_pressure)).to eq "Vapor pressure"
        expect(subject.col_name(:frost)).to eq "Frost days"
      end
    end

    describe ".valid_units" do
      it "returns a units array if col_attr has one" do
        expect(subject.valid_units(:min_temp)).to eq ["F", "C"]
      end

      it "returns default unit if col_attr doesn't have valid_units" do
        expect(subject.valid_units(:min_rh)).to eq ["%"]
      end

      it "returns a nil array if no units" do
        expect(subject.valid_units(:frost)).to eq [nil]
      end

      it "raises error if col is invalid" do
        expect { subject.valid_units("foo") }.to raise_error(ArgumentError)
      end
    end

    describe ".default_units" do
      it "gets the default unit given a column" do
        expect(subject.default_units(:min_temp)).to eq "C"
        expect(subject.default_units(:min_rh)).to eq "%"
        expect(subject.default_units(:frost)).to be_nil
      end
    end

    describe ".default_scale" do
      it "gets the gnuplot scale given column and units" do
        expect(subject.default_scale(col: :min_temp, units: "F")).to eq [0, 100]
        expect(subject.default_scale(col: :min_temp, units: "C")).to eq [-20, 40]
      end

      it "returns nil if no defined scale" do
        expect(subject.default_scale(col: :dew_point)).to be_nil
      end
    end
  end

  # only converts temperature
  describe ".convert" do
    context "when col has unit options" do
      let(:col) { :avg_temp }

      it "returns given value if units omitted" do
        expect(subject.convert(col:, value: 10)).to eq 10
      end

      it "returns given value if units: #{unit1}" do
        expect(subject.convert(col:, value: 10, units: unit1)).to eq 10
      end

      it "converts value if units: #{unit2}" do
        expect(subject.convert(col:, value: 10, units: unit2)).to eq UnitConverter.c_to_f(10)
      end

      it "raises error on invalid units" do
        expect { subject.convert(col:, value: 1, units: "foo") }.to raise_error(ArgumentError)
      end
    end

    context "when col has no unit options" do
      let(:col) { :min_rh }

      it "returns given value if units omitted" do
        expect(subject.convert(col:, value: 10))
      end

      it "returns given value if default unit" do
        expect(subject.convert(col:, value: 10, units: "%"))
      end
    end
  end

  describe ".image_title" do
    let(:col) { subject.default_col }
    let(:start_date) { "2023-1-1".to_date }
    let(:date) { "2023-2-1".to_date }
    let(:units) { unit1 }
    let(:args) { {col:, date:, start_date:, end_date: date, units:} }

    context "with defaults" do
      it { expect(subject.image_title(**args)).to be_an(String) }

      it "should show units in title" do
        expect(subject.image_title(**args)).to include(unit1)
        args[:units] = unit2
        expect(subject.image_title(**args)).to include(unit2)
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
end
