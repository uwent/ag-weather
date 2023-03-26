require "rails_helper"

RSpec.describe PestForecast do
  subject { PestForecast }

  describe "configuration" do
    describe ".col_names" do
      context "is valid" do
        it { expect(subject.col_names).to be_an Hash }
        it { expect(subject.col_names.keys).to match_array(subject.data_cols) }
      end
    end

    describe ".default_col" do
      context "is valid" do
        it { expect(subject.default_col).to_not be_nil }
        it { expect(subject.default_col).to be_an(Symbol) }
        it { expect(subject.default_col).to be_in(subject.data_cols) }
      end
    end

    describe ".image_subdir" do
      context "is valid" do
        it { expect(subject.image_subdir).to be_an(String) }
      end
    end

    describe ".default_scale" do
      context "is valid" do
        it { expect(subject.default_scale).to be_an(Array) }
        it { expect(subject.default_scale.size).to eq 2 }
      end
    end
  end

  describe ".new_from_weather" do
    before do
      @weather = FactoryBot.build(:weather)
      @pf = subject.new_from_weather(@weather)
    end

    it { expect(@pf).to be_valid }

    context "carries over values from weather" do
      %i[date latitude longitude].each do |col|
        it "uses #{col} value from weather" do
          expect(@pf.send(col)).to_not be_nil
          expect(@pf.send(col)).to eq @weather.send(col)
        end
      end
    end

    context "computes new values for pest models" do
      PestForecast.data_cols.each do |col|
        it "computes a valid value for #{col}" do
          expect(@pf.send(col)).to_not be_nil
        end
      end
    end
  end

  describe ".image_title" do
    let(:col) { subject.default_col }
    let(:start_date) { "2023-1-1".to_date }
    let(:date) { "2023-2-1".to_date }
    let(:args) { {col:, date:, start_date:, end_date: date} }

    it { expect(subject.image_title(**args)).to be_an(String) }
    it "puts data column title in image title" do
      expect(subject.image_title(**args)).to include(subject.col_names[col])
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
