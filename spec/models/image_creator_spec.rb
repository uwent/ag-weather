require "rails_helper"

RSpec.describe ImageCreator do
  subject { ImageCreator }

  describe "configurations" do
    describe ".url_path" do
      it { expect(subject.url_path).to be_an String }
      it { expect(subject.url_path).to_not be nil }
    end

    describe ".file_dir" do
      it { expect(subject.file_dir).to be_an String }
      it { expect(subject.file_dir).to_not be nil }
    end

    describe ".temp_dir" do
      it { expect(subject.temp_dir).to be_an String }
      it { expect(subject.temp_dir).to_not be nil }
    end
  end

  describe ".temp_filename" do
    context "creates a temporary filename for gnuplot data" do
      it "should start with the rail configured directory" do
        Rails.configuration.x.image.temp_directory = "/tmp/foo"
        expect(subject.temp_filename("bar")).to start_with("/tmp/foo")
      end

      it "should end with the value passed in" do
        expect(subject.temp_filename("foo")).to end_with(".foo")
      end
    end
  end

  describe ".get_min_max" do
    context "calculates min and max auto range for gnuplot" do
      # min_max also ensures the scale bar doesn't have small decimal divisions
      it "should return 0 if null value provided" do
        expect(subject.get_min_max(nil, nil)).to eq([0, 0])
      end

      it "should round to next tenth below/above min/max when range is <= 1" do
        expect(subject.get_min_max(0.1234, 0.2345)).to eq([0.1, 0.4])
      end

      it "should round to nearest unit below/above min/max when data range is <= 10" do
        expect(subject.get_min_max(0.1234, 2.3456)).to eq([0, 3])
      end

      it "should round to nearest ten below/above min/max when range > 10" do
        expect(subject.get_min_max(1.2345, 23.4567)).to eq([0, 30])
      end
    end
  end

  describe ".create_data_file" do
    let(:file_mock) { double("file") }
    let(:grid_mock) {
      {
        [1, 1] => rand,
        [1, 2] => rand,
        [2, 1] => rand,
        [2, 2] => rand
      }
    }

    # should write a line for each point and a blank line for each latitude change
    it "should write to a datafile" do
      expected_lines = grid_mock.size + 2 - 1
      expect(subject).to receive(:temp_filename).and_return("foo")
      allow(File).to receive(:open).with("foo", "w").and_yield(file_mock)
      expect(file_mock).to receive(:puts).exactly(expected_lines).times

      subject.create_data_file(grid_mock)
    end
  end

  describe ".run_gnuplot" do
    let(:datafile_name) { "foo.dat" }
    let(:args) {
      {
        datafile_name:,
        title: "some title",
        min: 0,
        max: 100,
        extents: [1, 2, 3, 4]
      }
    }

    context "on success" do
      before do
        allow(subject).to receive(:system).and_return true
      end

      it "should call gnuplot" do
        allow(subject).to receive(:temp_filename).and_return("foo")
        expect(subject).to receive(:system).with(/gnuplot/).exactly(1).times
        subject.run_gnuplot(**args)
      end

      it "should delete temporary data file" do
        expect(FileUtils).to receive(:rm_f).with(datafile_name)
        subject.run_gnuplot(**args)
      end
    end

    it "should raise error on failure" do
      allow(subject).to receive(:system).and_return false
      expect { subject.run_gnuplot(**args) }.to raise_error(StandardError)
    end
  end

  describe ".run_composite" do
    let(:gnuplot_image) { "temp.png" }
    let(:file) { "final.png" }
    let(:args) { {gnuplot_image:, file:} }

    context "on success" do
      before do
        allow(subject).to receive(:system).and_return true
      end

      it "should call composite" do
        expect(subject).to receive(:system).with(/composite/).exactly(1).times
        subject.run_composite(**args)
      end

      it "should return filename on success" do
        expect(subject.run_composite(**args)).to eq file
      end

      it "should place filename in subdir if specified" do
        args[:subdir] = "subdir"
        expect(subject).to receive(:system).with(/subdir/)
        subject.run_composite(**args)
      end

      it "should delete gnuplot image" do
        expect(FileUtils).to receive(:rm_f).with(gnuplot_image)
        subject.run_composite(**args)
      end
    end

    it "should raise error on failure" do
      allow(subject).to receive(:system).and_return false
      expect { subject.run_composite(**args) }.to raise_error(StandardError)
    end
  end
end
