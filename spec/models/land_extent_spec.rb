require "rails_helper"

RSpec.describe LandExtent, type: :model do
  let(:lats) { BigDecimal("38")..BigDecimal("50") }
  let(:longs) { BigDecimal("-98")..BigDecimal("-82") }
  let(:step) { 0.1 }

  describe "basic elements" do
    it "has correct default values" do
      expect(LandExtent.latitudes).to eq(lats)
      expect(LandExtent.longitudes).to eq(longs)
      expect(LandExtent.step).to eq(step)
    end

    it "has correct values for lat/long min/max" do
      expect(LandExtent.min_lat).to eq(lats.min)
      expect(LandExtent.max_lat).to eq(lats.max)
      expect(LandExtent.min_long).to eq(longs.min)
      expect(LandExtent.max_long).to eq(longs.max)
    end

    it "has the correct range definitions" do
      expect(LandExtent.min_lat).to eq(LandExtent.latitudes.min)
      expect(LandExtent.max_lat).to eq(LandExtent.latitudes.max)
      expect(LandExtent.min_long).to eq(LandExtent.longitudes.min)
      expect(LandExtent.max_long).to eq(LandExtent.longitudes.max)
    end
  end

  describe ".inside?" do
    it "insides are inside" do
      expect(LandExtent.inside?(lats.min, longs.min)).to be true
      expect(LandExtent.inside?(lats.min, longs.max)).to be true
      expect(LandExtent.inside?(lats.max, longs.min)).to be true
      expect(LandExtent.inside?(lats.max, longs.max)).to be true
    end

    it "outsides are outside" do
      expect(LandExtent.inside?(lats.min - 1, longs.min - 1)).to be false
      expect(LandExtent.inside?(lats.max + 1, longs.max + 1)).to be false
    end
  end

  describe ".random_point" do
    it "generates a random point within extents" do
      1.upto(5) do
        pt = LandExtent.random_point
        expect(pt).to be_kind_of(Array)
        expect(LandExtent.inside?(*pt)).to be true
      end
    end
  end
end
