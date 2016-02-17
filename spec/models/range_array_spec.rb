require "rails_helper"

RSpec.describe RangeArray  do
  context "initialize" do
    it "can make a range array with proper min, max, and step" do
      range = RangeArray.new(10, 20, 0.1)
      expect(range).to be_truthy
    end

    it "can't make a range array where the min is larger than the max" do
      expect { RangeArray.new(20, 0, 1) }.to raise_error(TypeError)
    end

    it "can't make a range array where the step is 0" do
      expect { RangeArray.new(0, 20, 0) }.to raise_error(TypeError)
    end

    it "can't make a range array where the step less than 0" do
      expect { RangeArray.new(0, 20, -0.1) }.to raise_error(TypeError)
    end

    it "can't make a range array where the step is less than the max - min." do
      expect { RangeArray.new(0, 2, 2.1) }.to raise_error(TypeError)
    end
  end

  context "number of points" do
    it "can be calculated for step 1" do
      ra = RangeArray.new(0, 10, 1)
      expect(ra.number_of_points).to eq 11
    end

    it "can calculate for fractional steps" do
      ra = RangeArray.new(0, 10, 0.1)
      expect(ra.number_of_points).to eq 101
    end

    it "can calcluate for min, max, and step where the last point isn't on max" do
      ra = RangeArray.new(0, 10.2, 0.5)
      expect(ra.number_of_points).to eq 21
    end
  end

  context "point_at_index" do
    let (:ra) { RangeArray.new(0, 10, 0.5) }
    it "can't find point for a negative index" do
      expect { ra.point_at_index(-1) }.to raise_error(IndexError)
    end

    it "can't find point for a index beyond the range" do
      expect { ra.point_at_index(21) }.to raise_error(IndexError)
    end

    it "will find the actual point value for index in range" do
      expect(ra.point_at_index(0)).to eql 0.0
      expect(ra.point_at_index(5)).to eql 2.5
      expect(ra.point_at_index(20)).to eql 10.0
    end
  end

  context "closest_point" do
    let (:ra) { RangeArray.new(0, 10.4, 0.5) }
    it "will find the minimum point if given point less the min of range" do
      expect(ra.closest_point(-1.0)).to eq 0.0
    end

    it "will find the maximum point in the range if given point larger" do
      expect(ra.closest_point(11.0)).to eq 10.0
    end

    it "will find a point in the range if pass point within range and on point" do
      expect(ra.closest_point(4.5)).to eq 4.5
    end

    it "will find closest defined point to point in range, not on pooint" do
      expect(ra.closest_point(1.7)).to eq 1.5
    end
  end

  context "includes_point?" do
    let (:ra) { RangeArray.new(-1.0, 10.4, 0.5) }
    it "will affirm a point is in the range and on point" do
      expect(ra.includes_point?(6.5)).to be_truthy
      expect(ra.includes_point?(-1.0)).to be_truthy
      expect(ra.includes_point?(10.0)).to be_truthy
    end

    it "will deny point that is in range but not coincident with defined point" do
      expect(ra.includes_point?(6.55)).to be_falsey
    end

    it "will deny a point that is over the maximum" do
      expect(ra.includes_point?(10.5)).to be_falsey
    end

    it "will deny a point that is under the minmum" do
      expect(ra.includes_point?(-1.5)).to be_falsey
    end
  end

  context "index_for_point" do
    let (:ra) { RangeArray.new(5.0, 11.2, 1) }

    it "will not find an index for point less than minimum" do
      expect {ra.index_for_point(4.0)}.to raise_error(IndexError)
    end

    it "will not find an index to given point in range if not on defined point" do
      expect {ra.index_for_point(5.5)}.to raise_error(IndexError)

    end

    it "will find index for defined points" do
      expect(ra.index_for_point(5.0)).to eq 0
      expect(ra.index_for_point(8.0)).to eq 3
      expect(ra.index_for_point(11.0)).to eq 6
    end
  end

  context "[]" do
    let (:ra) { RangeArray.new(10, 15, 0.1) }
    it "will not find a value for point less than minimum" do
      expect { ra[4.0] }.to raise_error(IndexError)
    end

    it "will not find a value for point in range if not on defined point" do
      expect { ra[10.05] }.to raise_error(IndexError)
    end

    it "will find the value stored at a defined point" do
      ra[10.0] = "foo"
      ra[15.0] = "bar"

      expect(ra[10.0]).to eq 'foo'
      expect(ra[15.0]).to eq 'bar'
    end

    it "will find an empty value for given index not stored" do
      expect(ra[10.3]).to be_nil
    end
  end

  context "[]=" do
    let (:ra) { RangeArray.new(5.0, 11, 0.5) }

    it "will not store a value for point less than minimum" do
      expect { ra[4.0] = "foo" }.to raise_error(IndexError)
    end

    it "will not store a value for point in range if not on defined point" do
      expect { ra[10.1] = "bar" }.to raise_error(IndexError)
    end

    it "will not store a value for point greater than max" do
      expect { ra[11.5] = "baz" }.to raise_error(IndexError)
    end

    it "will store values at defined points" do
      ra[5.0] = "foo"
      ra[11.0] = "bar"

      expect(ra[5.0]).to eq 'foo'
      expect(ra[11.0]).to eq 'bar'
    end
  end
end
