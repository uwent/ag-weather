require "rails_helper"

RSpec.describe WiExtent do
  subject { WiExtent }

  describe "defines the correct extent" do
    it "has correct extents" do
      expect(subject.lat_range).to eq 42.4..47.2
      expect(subject.lng_range).to eq(-93.0..-86.7)
    end

    it "has a valid extents" do
      expect(subject.min_lat < subject.max_lat).to be true
      expect(subject.min_lng < subject.max_lng).to be true
    end

    it "is smaller than the maximum extent" do
      expect(LandExtent.lat_range === subject.lat_range).to be true
      expect(LandExtent.lng_range === subject.lng_range).to be true
    end
  end
end
