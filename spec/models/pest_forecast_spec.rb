require "rails_helper"

RSpec.describe PestForecast, type: :model do

  describe "calculating potato blight dsv" do
    it 'uses avg_temp_rh_over_85 when present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(87)
      expect(weatherSpy).to receive(:avg_temp_rh_over_85)
      PestForecast.compute_potato_blight_dsv(weatherSpy)

    end

    it 'users avg_temperature when avg_temp_rh_over_85 is not present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(nil)
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_potato_blight_dsv(weatherSpy)

    end
  end

  describe "calculating carrot foliar dsv" do
    it 'uses avg_temp_rh_over_85 when present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(87)
      expect(weatherSpy).to receive(:avg_temp_rh_over_85)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)

    end

    it 'users avg_temperature when avg_temp_rh_over_85 is not present' do
      weatherSpy = spy('weather')
      allow(weatherSpy).to receive(:avg_temp_rh_over_85).and_return(nil)
      allow(weatherSpy).to receive(:avg_temperature).and_return(75)
      expect(weatherSpy).to receive(:avg_temperature)
      PestForecast.compute_carrot_foliar_dsv(weatherSpy)

    end
  end

end
