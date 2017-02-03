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

  context "closest_point" do
    let(:min_lat) { 10.0 }
    let(:max_lat) { 15.0 }
    let(:min_long) { 0.0 }
    let(:max_long) { 5.0 }
    let(:step) { 1.0 }
    let(:land_grid) { LandGrid.new(min_lat, max_lat, min_long, max_long, step) }

    it "should find a point passed in if coincides with a defined point" do
      expect(land_grid.closest_point(11, 4)).to eq [11.0, 4.0]
    end

    it "should give the minimum latitude if passed lower value" do
      expect(land_grid.closest_point(min_lat - 1, min_long)).to eq [min_lat, min_long]
    end

    it "should give the maximum latitude if passed higher value" do
      expect(land_grid.closest_point(max_lat + 1, min_long)).to eq [max_lat,min_long]
    end

    it "should give the minimum longitude if passed lower value" do
      expect(land_grid.closest_point(min_lat, min_long - 1)).to eq [min_lat, min_long]
    end

    it "should give the maximum latitude if passed higher value" do
      expect(land_grid.closest_point(max_lat, max_long + 1)).to eq [max_lat, max_long]
    end
  end

  context "enumerable" do
    let (:land_grid) { LandGrid.new(1, 2, 3, 4, 0.5)}

    it "implements each" do
      expect(land_grid).to respond_to(:each)
    end

    it "yields to each value stored in land grid" do
      (1.0..2.0).step(0.5) do |lat|
        (3.0..4.0).step(0.5) do |long|
          land_grid[lat,long] = 17
        end
      end
      expect { |b| land_grid.each(&b) }.to yield_control.exactly(9).times
    end
  end

  context "[]=" do
    let (:land_grid) { LandGrid.new(5, 10, 15, 20, 0.5)}

    it "should raise error if latitude is not defined in grid" do
      expect{ land_grid[17.1, 15] = 'foo'}.to raise_error(IndexError)
    end

    it "should raise error if longitude is not defined in grid" do
      expect{ land_grid[5.5, 16.99] = 'foo'}.to raise_error(IndexError)
    end

    it "should store value at proper point" do
      land_grid[5.5, 15] = 'foo'
      expect(land_grid[5.5, 15]).to eq 'foo'
    end
  end

  context "[]" do
    let (:land_grid) { LandGrid.new(5, 10, 15, 20, 0.5)}

    it "should raise error if latitude is not defined in grid" do
      expect{ land_grid[17.1, 15]}.to raise_error(IndexError)
    end

    it "should raise error if longitude is not defined in grid" do
      expect{ land_grid[5.5, 16.99]}.to raise_error(IndexError)
    end

    it "should find nothing at proper point that hasn't been stored" do
      expect(land_grid[5.5, 15]).to be_nil
    end

    it "should find a previously saved value at proper point" do
      land_grid[5.0, 15.0] = 'foo'
      land_grid[10.0, 20.0] = 'bar'
      expect(land_grid[5.0, 15.0]).to eq 'foo'
      expect(land_grid[10.0, 20.0]).to eq 'bar'
    end
  end

  context "wisconsin grid" do
    it 'should create a grid of Wisconsin' do
      land_grid = LandGrid.wisconsin_grid
      expect(land_grid).to_not be_nil
    end
  end
end
