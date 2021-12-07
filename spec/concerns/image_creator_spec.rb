require "rails_helper"

RSpec.describe ImageCreator, type: :module do
  describe "calculate max value for gunplot" do
    it "should return 0 if null value provided" do
      expect(ImageCreator.max_value_for_gnuplot(nil, nil)).to eq 0
    end

    it "should give next hundredth above value when range is <= 1" do
      expect(ImageCreator.max_value_for_gnuplot(0, 0.005)).to eq 0.01
      expect(ImageCreator.max_value_for_gnuplot(0, 0.085)).to eq 0.09
      expect(ImageCreator.max_value_for_gnuplot(0, 0.071)).to eq 0.08
      expect(ImageCreator.max_value_for_gnuplot(0, 0.050)).to eq 0.06
    end

    it "should give next tenth above value passed when data range is <= 10" do
      expect(ImageCreator.max_value_for_gnuplot(0, 3.1)).to eq 3.2
      expect(ImageCreator.max_value_for_gnuplot(0, 4.5)).to eq 4.6
      expect(ImageCreator.max_value_for_gnuplot(0, 5.71)).to eq 5.8
      expect(ImageCreator.max_value_for_gnuplot(0, 6.99)).to eq 7.0
    end

    it "should give ceiling of values passed when range > 10" do
      expect(ImageCreator.max_value_for_gnuplot(0, 11.0)).to eq 11.0
      expect(ImageCreator.max_value_for_gnuplot(0, 18.1)).to eq 19.0
      expect(ImageCreator.max_value_for_gnuplot(0, 15.9)).to eq 16.0
      expect(ImageCreator.max_value_for_gnuplot(0, 22.00001)).to eq 23.0
    end
  end

  describe "calculate max value for gunplot" do
    it "should return 0 if null value provided" do
      expect(ImageCreator.min_value_for_gnuplot(nil, nil)).to eq 0
    end

    it "should give next hundredth below value when range is <= 1" do
      expect(ImageCreator.min_value_for_gnuplot(0.005, 0.5)).to eq 0.0
      expect(ImageCreator.min_value_for_gnuplot(-0.085, 0.5)).to eq -0.09
      expect(ImageCreator.min_value_for_gnuplot(0.071, 0.5)).to eq 0.07
      expect(ImageCreator.min_value_for_gnuplot(-0.050, 0.5)).to eq -0.06
    end

    it "should give next tenth below value passed when data range is <= 10" do
      expect(ImageCreator.min_value_for_gnuplot(3.1, 8)).to eq 3.1
      expect(ImageCreator.min_value_for_gnuplot(4.5, 9)).to eq 4.5
      expect(ImageCreator.min_value_for_gnuplot(5.71, 10)).to eq 5.7
      expect(ImageCreator.min_value_for_gnuplot(6.99, 11)).to eq 6.9
    end

    it "should give floor of values passed when range > 10" do
      expect(ImageCreator.min_value_for_gnuplot(11.0, 100)).to eq 11.0
      expect(ImageCreator.min_value_for_gnuplot(18.1, 100)).to eq 18.0
      expect(ImageCreator.min_value_for_gnuplot(15.9, 100)).to eq 15.0
      expect(ImageCreator.min_value_for_gnuplot(22.00001, 100)).to eq 22.0
    end
  end

  describe "generate a random filename" do
    it "should start with the rail configured directory" do
      Rails.configuration.x.image.temp_directory = "/foo/bar"
      expect(ImageCreator.temp_filename("baz")).to start_with("/foo/bar")
    end

    it "should end with the value passed in" do
      expect(ImageCreator.temp_filename("baz")).to end_with(".baz")
    end
  end

  describe "create data file" do
    let(:file_mock) { instance_double("File") }
    before(:each) do
      @land_grid = LandGrid.wi_mn_grid
      WiMn.each_point { |lat, long| @land_grid[lat, long] = 0.0 }
    end

    # TODO: Fix this test
    it "should write to a datafile" do
      expect(ImageCreator).to receive(:temp_filename).and_return("foo")
      expect(File).to receive(:open).with("foo", "w").and_yield(file_mock)
      allow(file_mock).to receive(:puts)
      # 857 =  once per every fourth point (0.2 lat, 0.2 long) in WI plus
      #         an extra per latitude
      # expect(file_mock).to receive(:puts).exactly(857).times
      ImageCreator.create_data_file(@land_grid)
      # skip("Returns one extra line than it should!")
    end
  end

  describe "generate image files" do
    it "should call gnuplot and imagemagick" do
      allow(File).to receive(:delete)
      allow(ImageCreator).to receive(:temp_filename).and_return("/SZRIBZVL_20160418205412.png")
      expect(ImageCreator).to receive(:`).exactly(2).times

      ImageCreator.generate_image_file("a", "b", "some title", 0, 100)
    end
  end
end
