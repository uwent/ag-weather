require "rails_helper"

RSpec.describe WiExtent do
  describe "defines the correct extent" do
    it "has correct extents" do
      expect(described_class.lat_range).to eq 42.4..47.2
      expect(described_class.long_range).to eq -93.0..-86.7
    end

    it "has a valid extents" do
      expect(described_class.min_lat < described_class.max_lat).to be true
      expect(described_class.min_long < described_class.max_long).to be true
    end

    it "is smaller than the maximum extent" do
      expect(LandExtent.lat_range === described_class.lat_range).to be true
      expect(LandExtent.long_range === described_class.long_range).to be true
    end
  end
end
