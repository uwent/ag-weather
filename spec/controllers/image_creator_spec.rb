require "rails_helper"

RSpec.describe ImageCreator do
  describe "calculate maximum value for gunplot" do
    it 'should return 0 if null value provided' do
      expect(ImageCreator.max_value_for_gnuplot(nil)).to eq 0
    end

    it 'should give next hundredth above value passed for values less 0.1' do
      expect(ImageCreator.max_value_for_gnuplot(0.005)).to eq 0.01
      expect(ImageCreator.max_value_for_gnuplot(0.085)).to eq 0.09
      expect(ImageCreator.max_value_for_gnuplot(0.071)).to eq 0.08
      expect(ImageCreator.max_value_for_gnuplot(0.050)).to eq 0.06
    end

    it 'should give next tenth above value passed for values > 0.1 and < 1' do
      expect(ImageCreator.max_value_for_gnuplot(0.1)).to eq 0.2
      expect(ImageCreator.max_value_for_gnuplot(0.5)).to eq 0.6
      expect(ImageCreator.max_value_for_gnuplot(0.71)).to eq 0.8
      expect(ImageCreator.max_value_for_gnuplot(0.99)).to eq 1.0
    end

    it 'should give ceiling of values passed for values >= 1' do
      expect(ImageCreator.max_value_for_gnuplot(1.0)).to eq 1.0
      expect(ImageCreator.max_value_for_gnuplot(18.1)).to eq 19.0
      expect(ImageCreator.max_value_for_gnuplot(5.9)).to eq 6.0
      expect(ImageCreator.max_value_for_gnuplot(2.00001)).to eq 3.0
    end
  end

  describe "generate a random filename" do
    it 'should start with the rail configured directory' do
      Rails.configuration.x.image.temp_directory = '/foo/bar'
      expect(ImageCreator.temp_filename('baz')).to start_with('/foo/bar')
    end

    it 'should end with the value passed in' do
      expect(ImageCreator.temp_filename('baz')).to end_with('.baz')
    end
  end

  describe "create data file" do
    let(:file_mock) { instance_double("File") }
    before(:each) do
      @land_grid = LandGrid.wi_mn_grid
      WiMn.each_point { |lat, long| @land_grid[lat, long] = 0.0 }
    end

    it 'should write to a datafile' do
      expect(ImageCreator).to receive(:temp_filename).and_return('foo')
      expect(File).to receive(:open).with("foo", "w").and_yield(file_mock)
      # 2541 =  once per every fourth point (0.2 lat, 0.2 long) in WI_MN plus
      #         an extra per latitude
      expect(file_mock).to receive(:puts).exactly(2541).times
      ImageCreator.create_data_file(@land_grid)
    end
  end
  
  describe "generate image files" do
    it 'should call gnuplot and imagemagick' do
      allow(File).to receive(:delete)
      allow(ImageCreator).to receive(:temp_filename).and_return('/SZRIBZVL_20160418205412.png')
      expect(ImageCreator).to receive(:`).exactly(2).times

      ImageCreator.generate_image_file('a', 'b', 10, 'some title')
    end
  end
end
