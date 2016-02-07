require "rails_helper"

RSpec.describe LandGrid  do
  context "initialize" do
    it "can make a grid with proper latitudes, longitudes, and step" do
      grid = LandGrid.new(10, 20, 30, 40, 0.1)
      expect(grid).to be_truthy
    end

    it "should raise an exception if the min latitude is larger than max"  do
      expect { LandGrid.new(20, 19, 30, 40, 0.1) }.to raise_error(TypeError)
    end

    it "should raise an exception if the min longitude is larger than max"  do
      expect { LandGrid.new(0, 19, 20, 20, 0.1) }.to raise_error(TypeError)
    end

    it "should raise an exception if the step is larger than latitude diff"  do
      expect { LandGrid.new(0, 1, 0, 10, 2) }.to raise_error(TypeError)
    end

    it "should raise an exception if the step is larger than longitude diff"  do
      expect { LandGrid.new(0, 10, 0, 1, 2) }.to raise_error(TypeError)
    end

    it "should raise an exception if the step is zero or less"  do
      expect { LandGrid.new(0, 10, 0, 1, 0) }.to raise_error(TypeError)
    end
  end

  context "latitude_at_index" do
    let(:min_lat) { 42 }
    let(:max_lat) { 51 }
    let(:step) { 0.2 }
    let(:land_grid) { LandGrid.new(min_lat, max_lat, 15, 20, step) }

    it "should raise an error if given negative index" do
      expect { land_grid.latitude_at_index(-1) }.to raise_error(IndexError)
    end
    it "should raise an error if given index too large" do
      idx_edge = 1 + (max_lat - min_lat) / step
      expect { land_grid.latitude_at_index(idx_edge) }.to raise_error(IndexError)
    end

    it "should find a correct latitude given an index" do
      expect(land_grid.latitude_at_index(10)).to eq 44.0
    end
  end

  context "number_of_points" do
    it "should calculate correct number of points for whole steps" do
      expect(LandGrid.number_of_points(0, 10, 1)).to eq 11
    end
    it "should calculate correct number of points for factional steps" do
      expect(LandGrid.number_of_points(0, 10, 0.5)).to eq 21
    end
  end

  context "closest_latitude" do
    let(:min_lat) { 5 }
    let(:max_lat) { 10 }
    let(:land_grid) { LandGrid.new(min_lat, max_lat, 15, 20, 0.3) }

    it "should find the latitude passed in if coincides with a legal point" do
      expect(land_grid.closest_latitude(min_lat)).to eq min_lat
    end

    it "should give the minimum latitude if passed lower value" do
      expect(land_grid.closest_latitude(min_lat - 1)).to eq min_lat
    end

    it "should give the maximum latitude if passed higher value" do
      expect(land_grid.closest_latitude(max_lat + 1)).to eq 9.8
    end

    it "should return the closest legal latitude to passed value" do
      expect(land_grid.closest_latitude(5.49)).to eq 5.6
    end
  end

  context "longitude_at_index" do
    let(:min_long) { 33 }
    let(:max_long) { 48 }
    let(:step) { 0.3 }
    let(:land_grid) { LandGrid.new(15, 20, min_long, max_long, step) }

    it "should raise an error if given negative index" do
      expect { land_grid.longitude_at_index(-1) }.to raise_error(IndexError)
    end

    it "should raise an error if given index too large" do
      idx_edge = 1 + (max_long - min_long) / step
      expect { land_grid.longitude_at_index(idx_edge) }.to raise_error(IndexError)
    end

    it "should find a correct longitude given an index" do
      expect(land_grid.longitude_at_index(19)).to eq 38.7
    end
  end

  context "closest_longitude" do
    let(:min_long) { 33.2 }
    let(:max_long) { 42.8 }
    let(:land_grid) { LandGrid.new(15, 20, min_long, max_long, 0.2) }

    it "should find the longitude passed in if coincides with a legal point" do
      expect(land_grid.closest_longitude(min_long)).to eq min_long
    end

    it "should give the minimum longitude if passed lower value" do
      expect(land_grid.closest_longitude(min_long - 1)).to eq min_long
    end

    it "should give the maximum longitude if passed higher value" do
      expect(land_grid.closest_longitude(max_long + 1)).to eq max_long
    end

    it "should return the closest legal longitude to passed value" do
      expect(land_grid.closest_longitude(41.291)).to eq 41.2
    end
  end

  context "include_latitude?" do
    let (:land_grid) { LandGrid.new(15, 20, 15, 20, 0.15)}

    it "should indicate a latitude in range but not on the grid" do
      expect(land_grid.include_latitude?(15.2)).to be_falsey
    end

    it "should indicate a latitude lower than min is not on grid" do
      expect(land_grid.include_latitude?(14.85)).to be_falsey
    end

    it "should indicate a latitude higher than max is not on grid" do
      expect(land_grid.include_latitude?(20.15)).to be_falsey
    end

    it "should indicate a actual latitude on grid is true" do
      expect(land_grid.include_latitude?(15.90)).to be_truthy
    end
  end

  context "include_longitude?" do
    let (:land_grid) { LandGrid.new(15, 20, 15, 20, 0.5)}

    it "should indicate a longitude in range but not on the grid" do
      expect(land_grid.include_longitude? 15.49).to be_falsey
    end

    it "should indicate a longitude lower than min is not on grid" do
      expect(land_grid.include_longitude? 14.5).to be_falsey
    end

    it "should indicate a longitude higher than max is not on grid" do
      expect(land_grid.include_longitude? 20.5).to be_falsey
    end

    it "should indicate a minimum longitude on grid is true" do
      expect(land_grid.include_longitude? 15.0).to be_truthy
    end

    it "should indicate a maximum longitude on grid is true" do
      expect(land_grid.include_longitude? 20.0).to be_truthy
    end
  end

  context "[]=" do
    let (:land_grid) { LandGrid.new(15, 20, 15, 20, 0.5)}

    it "should raise error if latitude is not defined in grid" do
      expect{ land_grid[17.1, 15] = 'foo'}.to raise_error(IndexError)
    end

    it "should raise error if longitude is not defined in grid" do
      expect{ land_grid[15.5, 16.99] = 'foo'}.to raise_error(IndexError)
    end

    it "should store value at proper point" do
      land_grid[15.5, 15] = 'foo'
      expect(land_grid[15.5, 15]).to eq 'foo'
    end
  end

  context "[]" do
    let (:land_grid) { LandGrid.new(15, 20, 15, 20, 0.5)}

    it "should raise error if latitude is not defined in grid" do
      expect{ land_grid[17.1, 15]}.to raise_error(IndexError)
    end

    it "should raise error if longitude is not defined in grid" do
      expect{ land_grid[15.5, 16.99]}.to raise_error(IndexError)
    end

    it "should store value at proper point" do
      expect(land_grid[15.5, 15]).to be_nil
    end
  end

end
