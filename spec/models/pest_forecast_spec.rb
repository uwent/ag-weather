require "rails_helper"

RSpec.describe PestForecast, type: :model do

  describe "calculating potato blight dsv" do
    it 'uses avg_temp_rh_over_90 when hours_rh_over_90 present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(90)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(85)
      expect(weatherSpy).to receive(:avg_temp_rh_over_90)
      PestForecast.compute_potato_blight_dsv(weatherSpy)
    end

    it 'uses avg_temp_rh_over_85 when hours_rh_over_90 not present (for old rh method)' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(85)
      expect(weatherSpy).to receive(:avg_temp_rh_over_85)
      PestForecast.compute_potato_blight_dsv(weatherSpy)
    end

    it 'uses avg_temperature when neither rh threshold is present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(nil)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_potato_blight_dsv(weatherSpy)
    end
  end

  describe "calculating carrot foliar dsv" do
    it 'uses avg_temp_rh_over_90 when hours_rh_over_90 present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(10)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(90)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(85)
      expect(weatherSpy).to receive(:avg_temp_rh_over_90)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)
    end

    it 'uses avg_temp_rh_over_85 when hours_rh_over_90 not present (for old rh method)' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(12)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(85)
      expect(weatherSpy).to receive(:avg_temp_rh_over_85)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)
    end

    it 'uses avg_temperature when neither rh threshold is present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      allow(weatherSpy).to receive(:hours_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:hours_rh_over_85).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_90).and_return(nil)
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(nil)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)
    end
  end

  describe "calculating potato p days" do
    it 'uses min_temperature and max_temperature' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:min_temperature).and_return(50)
      allow(weatherSpy).to receive(:max_temperature).and_return(75)
      expect(weatherSpy).to receive(:min_temperature)
      expect(weatherSpy).to receive(:max_temperature)
      PestForecast.compute_potato_p_days(weatherSpy)
    end
  end

end
