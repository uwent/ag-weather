require "rails_helper"

RSpec.describe PestForecast, type: :model do

  describe "calculating late blight dsv" do
    it 'uses avg_temp_rh_over_90 and hours_rh_over_90 present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temp_rh_over_90)
      PestForecast.compute_potato_blight_dsv(weatherSpy)
    end

    it 'falls back on avg_temperature when avg_temp_rh_over_90 not present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temperature).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_potato_blight_dsv(weatherSpy)
    end

    it 'computes a late blight dsv from weather' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 14, avg_temp_rh_over_90: 25)
      dsv = PestForecast.compute_potato_blight_dsv(weather)
      expect(dsv).to eq 2
    end
  end

  describe "calculating carrot foliar dsv" do
    it 'uses avg_temp_rh_over_90 when hours_rh_over_90 present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temp_rh_over_90)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)
    end

    it 'falls back on avg_temperature when avg_temp_rh_over_90 not present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temperature).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)
    end

    it 'computes a carrot dsv' do
      weather = FactoryBot.create(:weather_datum, hours_rh_over_90: 10, avg_temp_rh_over_90: 20)
      dsv = PestForecast.compute_carrot_foliar_dsv(weather)
      expect(dsv).to eq 2
    end
  end

  describe "calculating potato p days" do
    it 'uses min_temperature and max_temperature' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:min_temperature).and_return(10)
      allow(weatherSpy).to receive(:max_temperature).and_return(25)
      expect(weatherSpy).to receive(:min_temperature)
      expect(weatherSpy).to receive(:max_temperature)
      PestForecast.compute_potato_p_days(weatherSpy)
    end

    it 'generates a pday from weather' do
      weather = FactoryBot.create(:weather_datum, min_temperature: 15, max_temperature: 25)
      pday = PestForecast.compute_potato_p_days(weather).round(2)
      expect(pday).to eq 9.25
    end
  end

  describe "calculating cercospora divs" do
    it 'uses hours_rh_over_90 and avg_temp_rh_over_90' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temp_rh_over_90)
      PestForecast.compute_cercospora_div(weatherSpy)
    end

    it 'falls back on avg_temperature when avg_temp_rh_over_90 not present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temperature).and_return(25)
      expect(weatherSpy).to receive(:hours_rh_over_90)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_cercospora_div(weatherSpy)
    end

    it 'computes a DIV from weather' do
      weather = FactoryBot.create(:weather_datum, avg_temp_rh_over_90: 15, hours_rh_over_90: 12)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 0
      weather = FactoryBot.create(:weather_datum, avg_temp_rh_over_90: 20, hours_rh_over_90: 12)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 3
      weather = FactoryBot.create(:weather_datum, avg_temp_rh_over_90: 35, hours_rh_over_90: 12)
      expect(PestForecast.compute_cercospora_div(weather)).to eq 7
    end
  end
end
