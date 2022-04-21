require "rails_helper"

RSpec.describe DataImporter, type: :model do
  describe ".elapsed" do
    it "returns a string of the elapsed time" do
      expect(DataImporter.elapsed(Time.current - 1.second)).to eq "1 second"
    end

    it "splits out minutes and seconds" do
      expect(DataImporter.elapsed(Time.current - 61.seconds)).to eq "1 minute and 1 second"
    end
  end
end
