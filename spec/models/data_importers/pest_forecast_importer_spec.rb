require "rails_helper"

RSpec.describe PestForecastImporter, type: :module do
  subject { PestForecastImporter }
  let(:data_class) { PestForecast }
  let(:import_class) { PestForecastDataImport }
  let(:date) { Date.yesterday }

  before do
    allow(data_class).to receive(:create_image)
  end

  describe ".data_class" do
    it { expect(subject.data_class).to eq data_class }
  end

  describe ".import" do
    it { expect(subject.import).to eq import_class }
  end

  describe ".data_sources_loaded?" do
    context "when data missing" do
      it { expect(subject.data_sources_loaded?(date)).to be_falsey }
    end

    context "when data present" do
      it "should be truthy" do
        WeatherDataImport.succeed(date)
        expect(subject.data_sources_loaded?(date)).to be_truthy
      end
    end
  end

  describe ".create_data_for_date" do
    let(:action) { subject.create_data_for_date(date) }

    context "when insolation and weather data are present" do
      before do
        FactoryBot.create(:weather, date:, latitude: 45, longitude: -89)
        FactoryBot.create(:insolation, date:, latitude: 45, longitude: -89)
        WeatherDataImport.succeed(date)
        InsolationDataImport.succeed(date)
      end

      it "adds a data_import record" do
        expect { action }.to change(import_class.successful, :count).by 1
      end

      it "adds a new evapotranspiration record" do
        expect { action }.to change(PestForecast, :count).by 1
      end
    end

    context "when insolation and weather data are not present" do
      it "creates an unsuccessful data import record" do
        expect { action }.to change(import_class.failed, :count).by 1
      end
    end
  end
end
