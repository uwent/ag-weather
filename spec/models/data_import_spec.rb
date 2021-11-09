require "rails_helper"

RSpec.describe DataImport, type: :model do
  describe ".days_to_load" do
    it "lists the days that have not successfully successful" do
      expect(DataImport.days_to_load.first).to be_a(Date)
    end

    it "only lists days that are within the defined range" do
      expect(DataImport.days_to_load.min).to be >= DataImport.earliest_date
    end

    context "no successful loads" do
      it "returns all dates in window" do
        expect(DataImport.days_to_load.count).to be DataImport::DAYS_BACK_WINDOW
      end
    end

    context "one successful load" do
      dates_to_load = DataImport.days_to_load
      reading_on = DataImport.earliest_date

      let!(:succesful_load) {
        DataImport.create!(
          status: "successful",
          readings_on: reading_on
        )
      }

      it "returns all other days" do
        expect(DataImport.days_to_load).to match_array(dates_to_load - [reading_on])
      end
    end

    describe ".on" do
      it "returns DataImport records on date" do
        expect(DataImport.on(Date.current)).to eq(DataImport.where(readings_on: Date.current))
      end
    end

    describe ".start" do
      it "creates a new DataImport record" do
        expect { DataImport.start(Date.current) }.to change(DataImport, :count).by 1
      end

      it "or updates existing record" do
        DataImport.start(Date.current)
        expect { DataImport.start(Date.current) }.to change(DataImport, :count).by 0
      end

      it "creates a record with status started" do
        new_record = DataImport.start(Date.current)
        expect(new_record.status).to eq("started")
      end
    end

    describe ".succeed" do
      it "creates a new DataImport record" do
        expect { DataImport.succeed(Date.current) }.to change(DataImport, :count).by 1
      end

      it "or updates existing record" do
        DataImport.start(Date.current)
        expect { DataImport.succeed(Date.current) }.to change(DataImport, :count).by 0
      end

      it "creates a record with status successful" do
        record = DataImport.succeed(Date.current)
        expect(record.status).to eq("successful")
      end
    end

    describe ".fail" do
      it "creates a new DataImport record" do
        expect { DataImport.fail(Date.current) }.to change(DataImport, :count).by 1
      end

      it "or updates an existing record" do
        DataImport.fail(Date.current)
        expect { DataImport.fail(Date.current) }.to change(DataImport, :count).by 0
      end

      it "creates a reco1rd with status unsuccessful" do
        record = DataImport.fail(Date.current)
        expect(record.status).to eq("unsuccessful")
      end
    end
  end
end
