require "rails_helper"

EPSILON = 0.0001
et = EvapotranspirationCalculator

RSpec.describe EvapotranspirationCalculator, type: :model do
  it "should convert degrees to radians" do
    expect(et.degrees_to_rads(180)).to eq Math::PI
    expect(et.degrees_to_rads(0)).to eq 0
    expect(et.degrees_to_rads(-180)).to eq(-1 * Math::PI)
  end

  it "should compute declin correctly" do
    expect(et.declin(20)).to be_within(EPSILON).of(-0.354775)
    expect(et.declin(180)).to be_within(EPSILON).of(0.4061183)
    expect(et.declin(364)).to be_within(EPSILON).of(-0.4045297)
  end

  it "should compute sunrise angle correctly" do
    expect(et.sunrise_angle(10, 45)).to be_within(EPSILON).of(1.1539124)
    expect(et.sunrise_angle(100, 30)).to be_within(EPSILON).of(1.648347)
    expect(et.sunrise_angle(200, 60)).to be_within(EPSILON).of(2.289568)
  end

  it "should compute sunrise hour correctly" do
    expect(et.sunrise_hour(10, 15)).to be_within(EPSILON).of(6.4152423)
    expect(et.sunrise_hour(100, 30)).to be_within(EPSILON).of(5.7037784)
    expect(et.sunrise_hour(200, 45)).to be_within(EPSILON).of(4.510417)
  end

  it "should compute number of hours of daylight correctly" do
    expect(et.day_hours(25, 15)).to be_within(EPSILON).of(11.284529)
    expect(et.day_hours(130, 29)).to be_within(EPSILON).of(13.3515053)
    expect(et.day_hours(330, 45)).to be_within(EPSILON).of(8.9181730)
  end

  it "should compute the av_eir correctly" do
    expect(et.av_eir(7)).to be_within(EPSILON).of(1414.4980626)
    expect(et.av_eir(187)).to be_within(EPSILON).of(1319.2984790)
    expect(et.av_eir(350)).to be_within(EPSILON).of(1413.2588336)
  end

  it "should compute to_eir correctly" do
    expect(et.to_eir(5, 15)).to be_within(EPSILON).of(28.8029040)
    expect(et.to_eir(143, 31)).to be_within(EPSILON).of(40.5145533)
    expect(et.to_eir(342, 44)).to be_within(EPSILON).of(11.3760482)
  end

  it "should compute to_clr correctly" do
    expect(et.to_clr(30, 44)).to be_within(EPSILON).of(11.6043893)
    expect(et.to_clr(165, 29)).to be_within(EPSILON).of(33.1694417)
    expect(et.to_clr(333, 10)).to be_within(EPSILON).of(25.1866956)
  end

  it "should compute lwu correctly" do
    expect(et.lwu(-10.0)).to be_within(EPSILON).of(22.5518166)
    expect(et.lwu(10.0)).to be_within(EPSILON).of(30.2297321)
    expect(et.lwu(30.0)).to be_within(EPSILON).of(39.7190017)
  end

  it "should compute sfactor correctly" do
    expect(et.sfactor(-20.0)).to be_within(EPSILON).of(-0.0008)
    expect(et.sfactor(9.0)).to be_within(EPSILON).of(0.540398)
    expect(et.sfactor(35.0)).to be_within(EPSILON).of(0.82255)
  end

  it "should compute sky emissions correctly" do
    expect(et.sky_emiss(0.49, -9.0)).to be_within(EPSILON).of(0.7549203)
    expect(et.sky_emiss(1.0, 3.0)).to be_within(EPSILON).of(0.8363996)
    expect(et.sky_emiss(30.0, 22.0)).to be_within(EPSILON).of(3.5834687)
  end

  it "should compute angstroms correctly" do
    expect(et.angstrom(0.4, -11.0)).to be_within(EPSILON).of(0.2058123)
    expect(et.angstrom(10.0, 5.0)).to be_within(EPSILON).of(-1.0955145)
    expect(et.angstrom(25.0, 25.0)).to be_within(EPSILON).of(-2.1072759)
  end

  it "should compute clr_ratio correctly" do
    expect(et.clr_ratio(9.0, 45, 45.0)).to be_within(EPSILON).of(0.6605110)
    expect(et.clr_ratio(20.0, 80, 30.0)).to be_within(EPSILON).of(0.7649150)
    expect(et.clr_ratio(30.0, 200, 15.0)).to be_within(EPSILON).of(0.9745485)
    expect(et.clr_ratio(40.0, 200, 15.0)).to eq 1.0
  end

  it "should compute lwnet correctly" do
    expect(et.lwnet(2.0, 22.0, 30.0, 200, 15.0)).to be_within(EPSILON).of(2.4552792)
    expect(et.lwnet(0.4, 2.0, 9.0, 60, 45.0)).to be_within(EPSILON).of(3.3314686)
    expect(et.lwnet(1.0, 17.0, 23.0, 120, 30.0)).to be_within(EPSILON).of(3.9672827)
  end

  # this is for the old coefficient
  # it "should compute potential evapotranspiration correctly" do
  #   expect(et.et(22.0, 2.0, 30.0, 200, 15.0)).to be_within(EPSILON).of(0.2905372)
  #   expect(et.et(2.0, 0.4, 9.0, 60, 45.0)).to be_within(EPSILON).of(0.0303162)
  #   expect(et.et(17.0, 1.0, 23.0, 120, 30.0)).to be_within(EPSILON).of(0.1767491)
  # end

  it "should compute potential evapotranspiration correctly" do
    expect(et.et(22.0, 2.0, 30.0, 200, 15.0)).to be_within(EPSILON).of(0.2859975)
    expect(et.et(2.0, 0.4, 9.0, 60, 45.0)).to be_within(EPSILON).of(0.0298425)
    expect(et.et(17.0, 1.0, 23.0, 120, 30.0)).to be_within(EPSILON).of(0.173987)
  end

  describe "compare internal et with agwx_biophys", skip: "Potential ET coefficient changed to match value in paper." do
    let(:min_temp) { 13.0 }
    let(:max_temp) { 20.0 }
    let(:avg_temp) { (min_temp + max_temp) / 2 }
    let(:vapor_pressure) { 0.6 }
    let(:latitude) { 45.0 }
    let(:longitude) { 92.0 }
    let(:date) { Date.current + 90.days }
    let(:et_instance) { (Class.new { include AgwxBiophys::ET }).new }
    let(:insolation_in_MJ_per_day) { 20.0 }
    let(:insolation_in_watts) { insolation_in_MJ_per_day / 0.0864 }

    it "should match" do
      old_et = et_instance.et(max_temp, min_temp, avg_temp,
        vapor_pressure,
        insolation_in_watts,
        date.yday, latitude)[0]
      new_et = et.et(avg_temp, vapor_pressure,
        insolation_in_MJ_per_day,
        date.yday, latitude)
      expect(new_et).to be_within(EPSILON).of(old_et)
    end
  end
end
