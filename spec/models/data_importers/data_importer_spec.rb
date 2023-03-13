require "rails_helper"

RSpec.describe DataImporter, type: :module do
  subject { DataImporter }

  describe ".latest_date" do
    it "provides the most recent date for data load" do
      expect(subject.latest_date).to eq DataImport.latest_date
    end
  end

  describe ".earliest_date" do
    it "provides the earliest date for data load" do
      expect(subject.earliest_date).to eq DataImport.earliest_date
    end
  end

  describe ".elapsed" do
    it "returns a string of the elapsed time" do
      expect(subject.elapsed(Time.current - 1.second)).to eq "1 second"
    end

    it "splits out minutes and seconds" do
      expect(subject.elapsed(Time.current - 61.seconds)).to eq "1 minute and 1 second"
    end
  end

  describe ".missing_dates" do
    it "returns an array of dates without data for a specific class" do
      start_date = 1.week.ago.to_date
      end_date = Date.yesterday
      all_dates = (start_date..end_date).collect { |d| d }
      days_to_load = [end_date]
      existing_dates = [start_date, start_date + 1.day, start_date + 2.days]
      expected_missing_dates = (all_dates - existing_dates + days_to_load).uniq.sort
      data_class = double("data")
      import_class = double("import")

      allow(subject).to receive(:data_class) { data_class }
      allow(data_class).to receive(:dates_in_range) { existing_dates }
      allow(subject).to receive(:import) { import_class }
      allow(import_class).to receive(:days_to_load) { days_to_load }

      expect(subject.missing_dates(start_date:, end_date:)).to eq expected_missing_dates
    end
  end
end
