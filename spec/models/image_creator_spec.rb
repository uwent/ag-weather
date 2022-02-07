require "rails_helper"

RSpec.describe ImageCreator, type: :module do
  describe "calculate min and max auto range for gunplot" do
    # min_max also ensures the scale bar doesn't have small decimal divisions
    it "should return 0 if null value provided" do
      expect(ImageCreator.get_min_max(nil, nil)).to eq([0, 0])
    end

    it "should round to next tenth below/above min/max when range is <= 1" do
      expect(ImageCreator.get_min_max(0.1234, 0.2345)).to eq([0.1, 0.4])
    end

    it "should round to nearest unit below/above min/max when data range is <= 10" do
      expect(ImageCreator.get_min_max(0.1234, 2.3456)).to eq([0, 3])
    end

    it "should round to nearest ten below/above min/max when range > 10" do
      expect(ImageCreator.get_min_max(1.2345, 23.4567)).to eq([0, 30])
    end
  end

  describe "generate a random filename" do
    it "should start with the rail configured directory" do
      Rails.configuration.x.image.temp_directory = "/tmp/foo"
      expect(ImageCreator.temp_filename("bar")).to start_with("/tmp/foo")
    end

    it "should end with the value passed in" do
      expect(ImageCreator.temp_filename("foo")).to end_with(".foo")
    end
  end

  describe "create data file" do
    let(:file_mock) { instance_double("File") }
    before(:each) do
      @land_grid = LandGrid.wisconsin_grid
      @land_grid.each_point { |lat, long| @land_grid[lat, long] = 0.0 }
    end

    it "should write to a datafile" do
      # should write a line for each point and a blank line for each latitude change
      expected_lines = @land_grid.num_points + @land_grid.num_latitudes - 1
      expect(ImageCreator).to receive(:temp_filename).and_return("foo")
      expect(File).to receive(:open).with("foo", "w").and_yield(file_mock)
      allow(file_mock).to receive(:puts)
      expect(file_mock).to receive(:puts).exactly(expected_lines).times
      ImageCreator.create_data_file(@land_grid)
    end
  end

  describe "generate image files" do
    it "should call gnuplot" do
      allow(ImageCreator).to receive(:temp_filename).and_return("/foo.png")
      expect(ImageCreator).to receive(:`).with(/gnuplot/).exactly(1).times
      ImageCreator.run_gnuplot("foo.dat", "some title", 0, 100, [1, 2, 3, 4])
    end

    it "should call composite" do
      expect(ImageCreator).to receive(:`).with(/composite/).exactly(1).times
      ImageCreator.run_composite("temp.png", "final.png", "")
    end
  end
end
