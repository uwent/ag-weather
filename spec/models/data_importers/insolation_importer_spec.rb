require "rails_helper"

RSpec.describe InsolationImporter, type: :module do
  subject { InsolationImporter }
  let(:data_class) { Insolation }
  let(:import_class) { InsolationDataImport }

  before do
    allow(data_class).to receive(:create_image)
  end

  describe ".data_class" do
    it { expect(subject.data_class).to eq data_class }
  end

  describe ".import" do
    it { expect(subject.import).to eq import_class }
  end

  describe ".formatted_date" do
    it "properly pads the date" do
      date = "2016-1-7".to_date
      expect(subject.formatted_date(date)).to eq "2016007"
    end

    it "includes the day of the year" do
      date = "2016-6-6".to_date
      expect(subject.formatted_date(date)).to eq("2016158")
    end
  end

  describe ".fetch_day" do
    let(:date) { Date.current }

    context "when valid data is found" do
      before do
        stub_request(:get, /prodserv1\.ssec\.wisc\.edu\/insolation\.*/)
          .to_return(body:
            "  1325       44.60        90.90/n" + # point within land extent
            "  1267       10.00        90.80/n" + # point outside land extent
            "-99999       44.60        90.70") # point within land extent, but invalid data
      end

      it "adds only good insolation data to the DB" do
        expect { subject.fetch_day(date) }.to change(data_class, :count).by 1
      end

      it "adds a successful import record on completion" do
        expect { subject.fetch_day(date) }.to change(import_class.successful, :count).by 1
      end

      it "marks the data import as unsuccessful on caught exception" do
        allow(HTTParty).to receive(:get).and_raise(StandardError)
        expect { subject.fetch_day(date) }.to change(import_class.failed, :count).by 1
      end
    end

    context "when response is 404" do
      before do
        stub_request(:get, /prodserv1\.ssec\.wisc\.edu\/insolation\.*/).to_return(body: "404")
      end

      it "raises error" do
        expect { subject.fetch_day(date) }.to change(import_class.failed, :count).by 1
      end
    end
  end
end
