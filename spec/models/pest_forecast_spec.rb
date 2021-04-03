require "rails_helper"

RSpec.describe PestForecast, type: :model do

  describe "calculating potato p days" do
    it 'generates a pday from weather' do
      weather = FactoryBot.create(:weather_datum, min_temperature: 15, max_temperature: 25)
      pday = PestForecast.compute_potato_p_days(weather).round(2)
      expect(pday).to eq 9.25
    end

    it 'defaults to 0 on bad weather data' do
      weather = FactoryBot.create(:weather_datum, min_temperature: nil, max_temperature: nil)
      expect(PestForecast.compute_potato_p_days(weather)).to eq 0
    end
  end

  describe "calculating late blight dsv" do
    it 'computes a late blight dsv from good weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 14, avg_temp_rh_over_90: 25)
      expect(PestForecast.compute_potato_blight_dsv(weather)).to eq 2
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 0, avg_temp_rh_over_90: nil)
      expect(PestForecast.compute_potato_blight_dsv(weather)).to eq 0
    end

    it 'computes a late blight dsv from old weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 14, avg_temperature: 25)
      expect(PestForecast.compute_potato_blight_dsv(weather)).to eq 2
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 0, avg_temperature: 25)
      expect(PestForecast.compute_potato_blight_dsv(weather)).to eq 0
    end

    it 'defaults to 0 with bad data' do
      weather = FactoryBot.create(:weather_datum,
        hours_rh_over_90: nil,
        hours_rh_over_85: nil,
        avg_temp_rh_over_90: nil,
        avg_temp_rh_over_85: nil,
        avg_temperature: nil
      )
      expect(PestForecast.compute_potato_blight_dsv(weather)).to eq 0
    end
  end

  describe "calculating carrot foliar dsv" do
    it 'computes a carrot dsv from good weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 10, avg_temp_rh_over_90: 20)
      expect(PestForecast.compute_carrot_foliar_dsv(weather)).to eq 2
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 0)
      expect(PestForecast.compute_carrot_foliar_dsv(weather)).to eq 0
    end

    it 'computes a carrot dsv from old weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 10, avg_temperature: 20)
      expect(PestForecast.compute_carrot_foliar_dsv(weather)).to eq 2
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 0)
      expect(PestForecast.compute_carrot_foliar_dsv(weather)).to eq 0
    end

    it 'defaults to 0 with bad data' do
      weather = FactoryBot.create(:weather_datum,
        hours_rh_over_90: nil,
        hours_rh_over_85: nil,
        avg_temp_rh_over_90: nil,
        avg_temp_rh_over_85: nil,
        avg_temperature: nil
      )
      expect(PestForecast.compute_carrot_foliar_dsv(weather)).to eq 0
    end
  end

  describe "calculating cercospora divs" do
    it 'computes a DIV from good weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 12, avg_temp_rh_over_90: 15)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 12, avg_temp_rh_over_90: 20)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 3
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 12, avg_temp_rh_over_90: 35)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 7
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 0)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
    end

    it 'computes a DIV from old weather data' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 12, avg_temperature: 15)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 12, avg_temperature: 20)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 3
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 12, avg_temperature: 35)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 7
      weather = FactoryBot.create(:weather_datum, hours_rh_over_85: 0)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
    end

    it 'defaults to 0 with bad data' do
      weather = FactoryBot.create(:weather_datum,
        hours_rh_over_90: nil,
        hours_rh_over_85: nil,
        avg_temp_rh_over_90: nil,
        avg_temp_rh_over_85: nil,
        avg_temperature: nil
      )
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
    end
  end
end
