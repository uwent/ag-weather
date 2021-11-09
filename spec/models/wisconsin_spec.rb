require "rails_helper"

RSpec.describe Wisconsin do
  describe "defines the correct extent" do
    it "has a valid extent" do
      expect(Wisconsin.min_lat < Wisconsin.max_lat).to be true
      expect(Wisconsin.min_long < Wisconsin.max_long).to be true
    end

    it "will create at least one grid point" do
      expect(Wisconsin.num_points > 0).to be true
    end

    it "is smaller than the maximum extent" do
      expect(LandExtent.latitudes === Wisconsin.latitudes).to be true
      expect(LandExtent.longitudes === Wisconsin.longitudes).to be true
    end
  end
end
