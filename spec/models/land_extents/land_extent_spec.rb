require "rails_helper"

RSpec.describe LandExtent do
  let(:lats) { BigDecimal("38")..BigDecimal("50") }
  let(:longs) { BigDecimal("-98")..BigDecimal("-82") }
  let(:step) { 0.1 }

  describe "basic elements" do
    it "has a valid extent" do
      expect(described_class.min_lat < described_class.max_lat).to be true
      expect(described_class.min_long < described_class.max_long).to be true
    end

    it "has correct default values" do
      expect(described_class.lat_range).to eq lats
      expect(described_class.long_range).to eq longs
      expect(described_class.step).to eq step
    end

    it "has correct values for lat/long min/max" do
      expect(described_class.min_lat).to eq lats.min
      expect(described_class.max_lat).to eq lats.max
      expect(described_class.min_long).to eq longs.min
      expect(described_class.max_long).to eq longs.max
    end

    it "has the correct range definitions" do
      expect(described_class.min_lat).to eq described_class.lat_range.min
      expect(described_class.max_lat).to eq described_class.lat_range.max
      expect(described_class.min_long).to eq described_class.long_range.min
      expect(described_class.max_long).to eq described_class.long_range.max
    end

    it "creates enumerables with step" do
      expect(described_class.latitudes).to eq described_class.lat_range.step(step)
      expect(described_class.longitudes).to eq described_class.long_range.step(step)
    end

    it "computes the correct number of points" do
      expect(described_class.num_points).to eq 19481
    end
  end

  describe ".inside?" do
    it "returns true when point is inside extent" do
      expect(described_class.inside?(lats.min, longs.min)).to be true
      expect(described_class.inside?(lats.min, longs.max)).to be true
      expect(described_class.inside?(lats.max, longs.min)).to be true
      expect(described_class.inside?(lats.max, longs.max)).to be true
      expect(described_class.inside?(45, -89)).to be true
    end

    it "returns false when point is outside extent" do
      expect(described_class.inside?(lats.min - 1, longs.min - 1)).to be false
      expect(described_class.inside?(lats.max + 1, longs.max + 1)).to be false
    end
  end

  describe ".random_point" do
    it "generates a random point within extents" do
      1.upto(5) do
        pt = described_class.random_point
        expect(pt).to be_kind_of(Array)
        expect(described_class.inside?(*pt)).to be true
      end
    end
  end

  describe ".each_point" do
    it "executes a block for each point in extent" do
      expect { |block| described_class.each_point(&block) }
        .to yield_control.exactly(described_class.num_points).times
    end

    it "returns values for lat and long" do
      expected_args = []
      lats.step(step).each do |lat|
        longs.step(step).each do |long|
          expected_args << [lat, long]
        end
      end
      expect { |block| described_class.each_point(&block) }
        .to yield_successive_args(*expected_args)
    end
  end
end
