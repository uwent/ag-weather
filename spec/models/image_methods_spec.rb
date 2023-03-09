require "rails_helper"

# fake version of any of the main data grid classes
class DummyClass
  extend ImageMethods

  def self.latest_date
    "2023-2-1".to_date
  end

  def self.default_col
    :temperature
  end

  def self.valid_units
    ["one", "two"]
  end

  def self.default_scale(*args)
    [0, 100]
  end

  def self.default_stat
    :bar
  end

  def self.column_names
    ["temperature"]
  end

  # stub GridMethods
  def self.hash_grid(**args)
    {}
  end

  def self.cumulative_hash_grid(**args)
    {}
  end

  # stub relation method
  def self.where(**args)
    []
  end
end

RSpec.describe ImageMethods, type: :module do
  let(:dc) { DummyClass }

  describe ".image_name_prefix" do
    it "creates a name prefix for the image file" do
      img_name = dc.image_name_prefix
      expect(img_name).to eq "dummyclass"
    end

    it "includes the summary stat if provided" do
      args = {stat: :foo}
      img_name = dc.image_name_prefix(**args)
      expect(img_name).to include("foo")
    end

    it "doesn't include the stat when it's the default" do
      args = {stat: :bar}
      img_name = dc.image_name_prefix(**args)
      expect(img_name).to_not include("bar")
    end
  end

  describe ".image_title_date" do
    it "formats a date for the image title" do
      end_date = "2023-1-1".to_date
      str = dc.image_title_date(end_date:)
      expect(str).to eq "Jan 1, 2023"
    end

    it "formats a date range for the image title" do
      start_date = "2023-1-1".to_date
      end_date = "2023-2-1".to_date
      str = dc.image_title_date(start_date:, end_date:)
      expect(str).to eq "Jan 1 - Feb 1, 2023"
    end

    it "includes year when spanning years" do
      start_date = "2022-12-1".to_date
      end_date = "2023-2-1".to_date
      str = dc.image_title_date(start_date:, end_date:)
      expect(str).to eq "Dec 1, 2022 - Feb 1, 2023"
    end
  end

  describe ".image_name" do
    it "raises error when no date provided" do
      expect { dc.image_name }.to raise_error(ArgumentError)
    end

    it "creates a formatted filename when single date" do
      args = {
        date: "2023-1-1".to_date,
        units: "Unit",
        extent: "wi",
        scale: [10, 200],
        stat: :max
      }
      name = dc.image_name(**args)
      expected_name = "max-dummyclass-unit-20230101-range-10-200-wi.png"
      expect(name).to eq expected_name
    end

    it "creates a formatted filename when date range" do
      args = {
        start_date: "2022-12-1".to_date,
        end_date: "2023-1-1".to_date
      }
      name = dc.image_name(**args)
      expected_name = "dummyclass-20221201-20230101.png"
      expect(name).to eq expected_name
    end
  end

  describe ".guess_image" do
    it "sends image args to .create_image when single date" do
      args = {
        date: Date.yesterday,
        foo: "bar"
      }
      expect(dc).to receive(:create_image).with(args)
      dc.guess_image(**args)
    end

    it "sends image args to .create_cumulative_image when date range" do
      args = {
        start_date: 1.week.ago.to_date,
        end_date: Date.yesterday,
        foo: "bar"
      }
      expect(dc).to receive(:create_cumulative_image).with(args)
      dc.guess_image(**args)
    end
  end

  describe ".create_image" do
    context "with defaults" do
      let(:date) { Date.yesterday }
      let(:col) { dc.default_col }
      let(:units) { dc.default_units }
      let(:scale) { dc.default_scale }

      it "calls .hash_grid with expected args" do
        expected_args = {date:, col:, units:, extent: LandExtent}
        expect(dc).to receive(:hash_grid).with(expected_args)
        dc.create_image(date:)
      end

      it "calls .image_title with expected args" do
        expected_args = {date:, col:, units:}
        expect(dc).to receive(:image_title).with(expected_args)
        dc.create_image(date:)
      end

      it "calls .image_name with expected args" do
        expected_args = {date:, col:, units:, extent: nil, scale:}
        expect(dc).to receive(:image_name).with(expected_args)
        dc.create_image(date:)
      end

      it "calls ImageCreator.create_image" do
        expect(ImageCreator).to receive(:create_image)
        dc.create_image(date:)
      end
    end
  end

  describe ".create_cumulative_image" do
    context "with defaults" do
      let(:start_date) { dc.latest_date.beginning_of_year }
      let(:end_date) { dc.latest_date }
      let(:col) { dc.default_col }
      let(:units) { dc.default_units }
      let(:stat) { dc.default_stat }

      it "calls .cumulative_hash_grid with expected args" do
        expected_args = {start_date:, end_date:, col:, units:, extent: LandExtent, stat:}
        expect(dc).to receive(:cumulative_hash_grid).with(expected_args)
        dc.create_cumulative_image
      end

      it "calls .image_title with expected args" do
        expected_args = {start_date:, end_date:, col:, units:, stat:}
        expect(dc).to receive(:image_title).with(expected_args)
        puts dc.latest_date
        dc.create_cumulative_image
      end

      it "calls .image_name with expected args" do
        expected_args = {start_date:, end_date:, col:, units:, extent: nil, scale: nil, stat:}
        expect(dc).to receive(:image_name).with(expected_args)
        dc.create_cumulative_image
      end

      it "calls ImageCreator.create_image" do
        expect(ImageCreator).to receive(:create_image)
        dc.create_cumulative_image
      end
    end
  end
end
