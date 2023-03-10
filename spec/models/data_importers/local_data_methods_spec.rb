require "rails_helper"

class DummyClass < DataImporter
  extend LocalDataMethods

  def self.earliest_date
    1.week.ago.to_date
  end

  def self.latest_date
    Date.today
  end

  def self.create_data_for_date(date)
  end
end

RSpec.describe LocalDataMethods, type: :module do
  let(:dc) { DummyClass }

  describe ".create_data" do
    context "when no missing dates" do
      it "doesn't call create_data_for_date" do
        allow(dc).to receive(:missing_dates).and_return([])
        expect(dc).to receive(:create_data_for_date).exactly(0).times
      end
    end

    context "when missing dates" do
      let(:all_dates) { (dc.earliest_date..dc.latest_date).to_a }
      let(:missing_dates) { all_dates.last(3) }
      let(:data_mock) { double("data") }
      let(:import_mock) { double("import") }

      before do
        allow(dc).to receive(:data_class).and_return(data_mock)
        allow(dc).to receive(:import).and_return(import_mock)
        allow(data_mock).to receive(:find_by).and_return(false)
      end

      it "calls create_data_for_date for each missing day" do
        allow(dc).to receive(:missing_dates).and_return(missing_dates)
        missing_dates.each do |date|
          expect(dc).to receive(:create_data_for_date).with(date).ordered.once
        end
        dc.create_data
      end

      it "calls create_data_for_date for each day when all_dates: true" do
        all_dates.each do |date|
          expect(dc).to receive(:create_data_for_date).with(date).ordered.once
        end
        dc.create_data(all_dates: true)
      end

      it "creates a successful import if data exists" do
        allow(data_mock).to receive(:find_by).and_return(true)
        all_dates.each do |date|
          expect(import_mock).to receive(:succeed).with(date).ordered.once
        end
        dc.create_data(all_dates: true)
      end

      it "calls create_data_for_date if exists but overwrite: true" do
        allow(data_mock).to receive(:find_by).and_return(true)
        all_dates.each do |date|
          expect(dc).to receive(:create_data_for_date).with(date).ordered.once
        end
        dc.create_data(all_dates: true, overwrite: true)
      end

      it "creates a fail record if create_data_for_date fails" do
        allow(dc).to receive(:create_data_for_date).and_raise StandardError
        all_dates.each do |date|
          expect(import_mock).to receive(:fail).with(date, kind_of(String)).ordered.once
        end
        dc.create_data(all_dates: true)
      end
    end
  end
end
