require "rails_helper"

RSpec.describe UnitConverter, type: :module do
  subject { UnitConverter }
  let(:epsilon) { 1e-6 }

  # for temperatures
  describe "converts between C and F" do
    inputs = {
      -40 => -40,
      0 => 32,
      23.3 => 73.94,
      100 => 212
    }

    describe ".c_to_f" do
      inputs.each do |x, y|
        it "returns #{y} given #{x}" do
          expect(subject.c_to_f(x)).to be_within(epsilon).of(y)
        end
      end
    end

    describe ".f_to_c" do
      inputs.each do |y, x|
        it "returns #{y} given #{x}" do
          expect(subject.f_to_c(x)).to be_within(epsilon).of(y)
        end
      end
    end
  end

  # for degree days
  describe "converts between CDD and FDD" do
    inputs = {
      0 => 0,
      42 => 75.6,
      123 => 221.4,
      428 => 770.4
    }

    describe ".cdd_to_fdd" do
      inputs.each do |x, y|
        it "returns #{y} given #{x}" do
          expect(subject.cdd_to_fdd(x)).to be_within(epsilon).of(y)
        end
      end
    end

    describe ".fdd_to_cdd" do
      inputs.each do |y, x|
        it "returns #{y} given #{x}" do
          expect(subject.fdd_to_cdd(x)).to be_within(epsilon).of(y)
        end
      end
    end
  end

  # for et and precip
  describe "converts between mm and in" do
    inputs = {
      0 => 0,
      42 => 1.6535433071,
      123 => 4.842519685,
      428 => 16.850393701
    }

    describe ".cdd_to_fdd" do
      inputs.each do |x, y|
        it "returns #{y} given #{x}" do
          expect(subject.mm_to_in(x)).to be_within(epsilon).of(y)
        end
      end
    end

    describe ".fdd_to_cdd" do
      inputs.each do |y, x|
        it "returns #{y} given #{x}" do
          expect(subject.in_to_mm(x)).to be_within(epsilon).of(y)
        end
      end
    end
  end

  # for insolation
  describe "converts between MJ and KWh" do
    inputs = {
      0 => 0,
      123 => 34.166666667,
      456.789 => 126.88583333,
      5015 => 1393.0555556
    }

    describe ".mj_to_kwh" do
      inputs.each do |x, y|
        it "returns #{y} given #{x}" do
          expect(subject.mj_to_kwh(x)).to be_within(epsilon).of(y)
        end
      end
    end
  end
end
