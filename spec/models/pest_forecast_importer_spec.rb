require "rails_helper"

RSpec.describe PestForecastImporter, type: :model do
  let(:date) { Date.current }

  describe ".create_forecast_data" do
    it "calls pest forecasts for every day returned by DataImport" do
      unloaded_days = [Date.yesterday, Date.current - 2.days]
      allow(PestForecastDataImport).to receive(:days_to_load).and_return(unloaded_days)
      expect(PestForecastImporter).to receive(:calculate_forecast_for_date).exactly(unloaded_days.count).times

      PestForecastImporter.create_forecast_data
    end
  end

  describe ".calculate_forecast_for_date" do
    let(:action) { PestForecastImporter.calculate_forecast_for_date(date) }

    context "when weather data is present" do
      before do
        WeatherDataImport.succeed(date)
      end

      it "adds a data_import record" do
        expect { action }.to change(PestForecastDataImport.successful, :count).by 1
      end

      it "adds a new pest forecast record" do
        FactoryBot.create(:weather_datum, date:)
        expect { action }.to change(PestForecast, :count)
      end
    end

    context "when weather data is not present" do
      it "will create an unsuccessful data import record" do
        expect { action }.to change(PestForecastDataImport.unsuccessful, :count)
      end
    end
  end
end
