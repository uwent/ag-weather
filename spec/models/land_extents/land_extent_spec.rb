require "rails_helper"

RSpec.describe LandExtent do
  subject { LandExtent }
  let(:lats) { BigDecimal(38)..BigDecimal(50) }
  let(:lngs) { BigDecimal("-98")..BigDecimal("-82") }
  let(:step) { 0.1 }

  describe "basic elements" do
    it "has a valid extent" do
      expect(subject.min_lat < subject.max_lat).to be true
      expect(subject.min_lng < subject.max_lng).to be true
    end

    it "has correct default values" do
      expect(subject.lat_range).to eq lats
      expect(subject.lng_range).to eq lngs
      expect(subject.step).to eq step
    end

    it "has correct values for lat/lng min/max" do
      expect(subject.min_lat).to eq lats.min
      expect(subject.max_lat).to eq lats.max
      expect(subject.min_lng).to eq lngs.min
      expect(subject.max_lng).to eq lngs.max
    end

    it "has the correct range definitions" do
      expect(subject.min_lat).to eq subject.lat_range.min
      expect(subject.max_lat).to eq subject.lat_range.max
      expect(subject.min_lng).to eq subject.lng_range.min
      expect(subject.max_lng).to eq subject.lng_range.max
    end

    it "creates enumerables with step" do
      expect(subject.latitudes).to eq subject.lat_range.step(step)
      expect(subject.longitudes).to eq subject.lng_range.step(step)
    end

    it "computes the correct number of points" do
      expect(subject.num_points).to eq 19481
    end
  end

  describe ".inside?" do
    it "returns true when point is inside extent" do
      expect(subject.inside?(lats.min, lngs.min)).to be true
      expect(subject.inside?(lats.min, lngs.max)).to be true
      expect(subject.inside?(lats.max, lngs.min)).to be true
      expect(subject.inside?(lats.max, lngs.max)).to be true
      expect(subject.inside?(45, -89)).to be true
    end

    it "returns false when point is outside extent" do
      expect(subject.inside?(lats.min - 1, lngs.min - 1)).to be false
      expect(subject.inside?(lats.max + 1, lngs.max + 1)).to be false
    end
  end

  describe ".random_point" do
    it "generates a random point within extents" do
      1.upto(5) do
        pt = subject.random_point
        expect(pt).to be_kind_of(Array)
        expect(subject.inside?(*pt)).to be true
      end
    end
  end

  describe ".each_point" do
    it "executes a block for each point in extent" do
      expect { |block| subject.each_point(&block) }
        .to yield_control.exactly(subject.num_points).times
    end

    it "returns values for lat and lng" do
      expected_args = []
      lats.step(step).each do |lat|
        lngs.step(step).each do |lng|
          expected_args << [lat, lng]
        end
      end
      expect { |block| subject.each_point(&block) }
        .to yield_successive_args(*expected_args)
    end
  end
end
