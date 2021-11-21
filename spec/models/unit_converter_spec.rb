require "rails_helper"

RSpec.describe UnitConverter, type: :module do
  let(:epsilon) { 0.000001 }

  describe "converts between temperature units" do
    it "should convert celcius to fahrenheit" do
      expect(UnitConverter.c_to_f(-40)).to eq(-40)
      expect(UnitConverter.c_to_f(0)).to eq(32)
      expect(UnitConverter.c_to_f(23.3)).to eq(73.94)
      expect(UnitConverter.c_to_f(100)).to eq(212)
    end

    it "should convert fahrenheit to celcius" do
      expect(UnitConverter.f_to_c(-40)).to eq(-40)
      expect(UnitConverter.f_to_c(32)).to eq(0)
      expect(UnitConverter.f_to_c(73.94)).to be_within(epsilon).of(23.3)
      expect(UnitConverter.f_to_c(212)).to eq(100)
    end

    it "should convert celcius degree days to fahrenheit" do
      expect(UnitConverter.cdd_to_fdd(0)).to eq(0)
      expect(UnitConverter.cdd_to_fdd(42)).to eq(75.6)
      expect(UnitConverter.cdd_to_fdd(123)).to eq(221.4)
    end

    it "should convert fahrenheit degree days to celcius" do
      expect(UnitConverter.fdd_to_cdd(0)).to eq(0)
      expect(UnitConverter.fdd_to_cdd(45)).to eq(25)
      expect(UnitConverter.fdd_to_cdd(126)).to eq(70)
    end
  end
end
