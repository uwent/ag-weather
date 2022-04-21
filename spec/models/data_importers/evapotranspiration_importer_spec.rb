require "rails_helper"

RSpec.describe EvapotranspirationImporter, type: :model do
  let(:date) { Date.current }

  describe ".create_et_data" do
    it "runs calculate_et_for_date for every day returned by DataImport" do
      unloaded_days = [Date.yesterday, Date.current - 2.days]
      allow(EvapotranspirationDataImport).to receive(:days_to_load).and_return(unloaded_days)
      expect(EvapotranspirationImporter).to receive(:calculate_et_for_date).exactly(unloaded_days.count).times
      EvapotranspirationImporter.create_et_data
    end
  end

  describe ".calculate_et_for_date" do
    let(:action) { EvapotranspirationImporter.calculate_et_for_date(date) }

    context "when insolation and weather data are present" do
      before do
        FactoryBot.create(:weather_datum, date:)
        FactoryBot.create(:insolation, date:)
        WeatherDataImport.succeed(date)
        InsolationDataImport.succeed(date)
      end

      it "adds a data_import record" do
        expect { action }.to change(EvapotranspirationDataImport.successful, :count)
      end

      it "adds a new evapotranspiration record" do
        expect { action }.to change(Evapotranspiration, :count)
      end
    end

    context "when insolation and weather data are not present" do
      it "creates an unsuccessful data import record" do
        expect { action }.to change(EvapotranspirationDataImport.unsuccessful, :count)
      end
    end
  end
end
