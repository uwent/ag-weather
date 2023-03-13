require "rails_helper"

RSpec.describe GridMethods, type: :module do
  subject { Insolation } # as a test class

  let(:latitudes) { 45..46 }
  let(:longitudes) { -89..-88 }
  let(:dates) { 3.days.ago.to_date..1.day.ago.to_date }

  before do
    # create valid grid
    dates.each do |date|
      latitudes.each do |lat|
        longitudes.each do |long|
          subject.create(latitude: lat, longitude: long, date:, insolation: 1.0)
        end
      end
    end

    # plus one outside of extent
    subject.create(latitude: 1, longitude: 1, date: dates.last, insolation: 1.0)
  end

  let(:grid_points) { 4 }
  let(:total_points) { 5 }

  describe ".all_for_date" do
    let(:relation) { subject.all_for_date(dates.last) }

    it { expect(relation.size).to eq total_points }
  end

  describe ".extent" do
    let(:extent) { subject.extent }

    it { expect(extent).to be_an(Hash) }

    it { expect(extent.keys).to match([:latitude, :longitude]) }

    it "returns lat and long extents of data" do
      expect(extent[:latitude]).to eq [1.0, latitudes.last.to_f]
      expect(extent[:longitude]).to eq [longitudes.first.to_f, 1.0]
    end
  end

  describe ".hash_grid" do
    context "with default arguments" do
      let(:grid) { subject.hash_grid(date: dates.last) }

      it { expect(grid).to be_an(Hash) }

      it "creates a grid containing points" do
        expect(grid.size).to eq grid_points
      end

      it "has values at each point" do
        expect(grid[[45.0, -89.0]]).to eq 1.0
        expect(grid[[46.0, -89.0]]).to eq 1.0
        expect(grid[[45.0, -88.0]]).to eq 1.0
        expect(grid[[46.0, -88.0]]).to eq 1.0
      end

      it "has nil value where undefined" do
        expect(grid[[1.0, 2.0]]).to be_nil
      end

      it "excludes point outside of extent" do
        expect(grid[[1.0, 1.0]]).to be_nil
      end
    end

    context "with alternate units" do
      let(:grid) { subject.hash_grid(date: dates.last, units: "KWh") }

      it "converts the values at each point" do
        expect(grid[[45.0, -89.0]]).to eq UnitConverter.mj_to_kwh(1.0)
        expect(grid[[46.0, -89.0]]).to eq UnitConverter.mj_to_kwh(1.0)
        expect(grid[[45.0, -88.0]]).to eq UnitConverter.mj_to_kwh(1.0)
        expect(grid[[46.0, -88.0]]).to eq UnitConverter.mj_to_kwh(1.0)
      end
    end
  end

  describe ".cumulative_hash_grid" do
    let(:start_date) { dates.first }
    let(:end_date) { dates.last }
    context "with default arguments" do
      let(:grid) { subject.cumulative_hash_grid(start_date:, end_date:) }

      it { expect(grid).to be_an(Hash) }

      it "creates a grid containing points" do
        expect(grid.size).to eq grid_points
      end

      it "has cumulative values at each point" do
        expect(grid[[45.0, -89.0]]).to eq 1.0 * dates.count
        expect(grid[[46.0, -89.0]]).to eq 1.0 * dates.count
        expect(grid[[45.0, -88.0]]).to eq 1.0 * dates.count
        expect(grid[[46.0, -88.0]]).to eq 1.0 * dates.count
      end

      it "has nil value where undefined" do
        expect(grid[[1.0, 2.0]]).to be_nil
      end
    end

    context "with alternate units" do
      let(:grid) { subject.cumulative_hash_grid(start_date:, end_date:, units: "KWh") }

      it "converts the values at each point" do
        expect(grid[[45.0, -89.0]]).to eq UnitConverter.mj_to_kwh(1.0 * dates.count)
        expect(grid[[46.0, -89.0]]).to eq UnitConverter.mj_to_kwh(1.0 * dates.count)
        expect(grid[[45.0, -88.0]]).to eq UnitConverter.mj_to_kwh(1.0 * dates.count)
        expect(grid[[46.0, -88.0]]).to eq UnitConverter.mj_to_kwh(1.0 * dates.count)
      end
    end

    context "with alternate sql aggregation function" do
      let(:grid) { subject.cumulative_hash_grid(start_date:, end_date:, stat: :avg) }

      it "returns the average at each grid point" do
        expect(grid[[45.0, -89.0]]).to eq 1.0
      end
    end

    context "with invalid arguments" do
      it "checks the given data col" do
        expect { subject.cumulative_hash_grid(col: "foo") }.to raise_error(ArgumentError)
      end

      it "checks the given extent" do
        expect { subject.cumulative_hash_grid(extent: "foo") }.to raise_error(ArgumentError)
      end

      it "checks the given units" do
        expect { subject.cumulative_hash_grid(units: "foo") }.to raise_error(ArgumentError)
      end

      it "checks the given stat" do
        expect { subject.cumulative_hash_grid(stat: "foo") }.to raise_error(ArgumentError)
      end
    end
  end
end
