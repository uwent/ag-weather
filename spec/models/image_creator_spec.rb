require "rails_helper"

RSpec.describe ImageCreator, type: :module do
  describe "calculate min and max auto range for gunplot" do
    # min_max also ensures the scale bar doesn't have small decimal divisions
    it "should return 0 if null value provided" do
      expect(ImageCreator.min_max(nil, nil)).to eq([0, 0])
    end

    it "should round to next tenth below/above min/max when range is <= 1" do
      expect(ImageCreator.min_max(0.1234, 0.2345)).to eq([0.1, 0.4])
    end

    it "should round to nearest unit below/above min/max when data range is <= 10" do
      expect(ImageCreator.min_max(0.1234, 2.3456)).to eq([0, 3])
    end

    it "should round to nearest ten below/above min/max when range > 10" do
      expect(ImageCreator.min_max(1.2345, 23.4567)).to eq([0, 30])
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
      @land_grid = LandGrid.wi_mn_grid
      WiMn.each_point { |lat, long| @land_grid[lat, long] = 0.0 }
    end

    # TODO: Fix this test
    # it "should write to a datafile" do
    #   expect(ImageCreator).to receive(:temp_filename).and_return("foo")
    #   expect(File).to receive(:open).with("foo", "w").and_yield(file_mock)
    #   allow(file_mock).to receive(:puts)
    #   # 857 =  once per every fourth point (0.2 lat, 0.2 long) in WI plus
    #   #         an extra per latitude
    #   # expect(file_mock).to receive(:puts).exactly(857).times
    #   ImageCreator.create_data_file(@land_grid)
    #   # skip("Returns one extra line than it should!")
    # end
  end

  describe "generate image files" do
    it "should call gnuplot and imagemagick" do
      allow(File).to receive(:delete)
      allow(ImageCreator).to receive(:temp_filename).and_return("/foo.png")
      expect(ImageCreator).to receive(:`).exactly(2).times
      ImageCreator.generate_image_file("foo.dat", "bar.png", "", "some title", 0, 100, [1, 2, 3, 4])
    end

    it "should rescue on error" do
      allow(ImageCreator).to receive(:`).and_raise(StandardError.new)
      expect(ImageCreator).to receive(:`).exactly(1).times
      expect(
        ImageCreator.generate_image_file("foo.dat", "bar.png", "", "some title", 0, 100, [1, 2, 3, 4])
      ).to eq("no_data.png")
    end
  end
end
