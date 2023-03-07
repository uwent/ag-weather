require "rails_helper"

RSpec.describe EvapotranspirationCalculator, type: :model do
  subject { EvapotranspirationCalculator }
  let(:epsilon) { 1e-6 }
  let(:pi) { Math::PI }

  describe ".degrees_to_rads" do
    it "should convert degrees to radians" do
      expect(subject.degrees_to_rads(180)).to eq pi
      expect(subject.degrees_to_rads(0)).to eq 0
      expect(subject.degrees_to_rads(-180)).to eq(-1 * pi)
    end
  end

  describe ".declin" do
    it "should compute declination angle correctly" do
      expect(subject.declin(20)).to be_within(epsilon).of -0.354775
      expect(subject.declin(180)).to be_within(epsilon).of 0.4061183
      expect(subject.declin(364)).to be_within(epsilon).of -0.4045297
    end
  end

  describe ".sunrise_angle" do
    it "should compute sunrise angle correctly" do
      expect(subject.sunrise_angle(10, 45)).to be_within(epsilon).of 1.1539124
      expect(subject.sunrise_angle(100, 30)).to be_within(epsilon).of 1.648347
      expect(subject.sunrise_angle(200, 60)).to be_within(epsilon).of 2.289568
    end
  end

  describe ".sunrise_hour" do
    it "should compute sunrise hour correctly" do
      expect(subject.sunrise_hour(10, 15)).to be_within(epsilon).of 6.4152423
      expect(subject.sunrise_hour(100, 30)).to be_within(epsilon).of 5.7037784
      expect(subject.sunrise_hour(200, 45)).to be_within(epsilon).of 4.510417
    end
  end

  describe ".day_hours" do
    it "should compute number of hours of daylight correctly" do
      expect(subject.day_hours(25, 15)).to be_within(epsilon).of 11.284529
      expect(subject.day_hours(130, 29)).to be_within(epsilon).of 13.3515053
      expect(subject.day_hours(330, 45)).to be_within(epsilon).of 8.9181730
    end
  end

  describe ".av_eir" do
    it "should compute the av_eir correctly" do
      expect(subject.av_eir(7)).to be_within(epsilon).of 1414.4980626
      expect(subject.av_eir(187)).to be_within(epsilon).of 1319.2984790
      expect(subject.av_eir(350)).to be_within(epsilon).of 1413.2588336
    end
  end

  describe ".to_eir" do
    it "should compute to_eir correctly" do
      expect(subject.to_eir(5, 15)).to be_within(epsilon).of 28.8029040
      expect(subject.to_eir(143, 31)).to be_within(epsilon).of 40.5145533
      expect(subject.to_eir(342, 44)).to be_within(epsilon).of 11.3760482
    end
  end

  describe ".to_clr" do
    it "should compute to_clr correctly" do
      expect(subject.to_clr(30, 44)).to be_within(epsilon).of 11.6043893
      expect(subject.to_clr(165, 29)).to be_within(epsilon).of 33.1694417
      expect(subject.to_clr(333, 10)).to be_within(epsilon).of 25.1866956
    end
  end

  describe ".lwu" do
    it "should compute lwu correctly" do
      expect(subject.lwu(-10.0)).to be_within(epsilon).of 22.5518166
      expect(subject.lwu(10.0)).to be_within(epsilon).of 30.2297321
      expect(subject.lwu(30.0)).to be_within(epsilon).of 39.7190017
    end
  end

  describe ".sfactor" do
    it "should compute sfactor correctly" do
      expect(subject.sfactor(-20.0)).to be_within(epsilon).of -0.0008
      expect(subject.sfactor(9.0)).to be_within(epsilon).of 0.540398
      expect(subject.sfactor(35.0)).to be_within(epsilon).of 0.82255
    end
  end

  describe ".sky_emiss" do
    context "when avg_v_press <= 0.5" do
      it "should compute sky emissisivity correctly" do
        expect(subject.sky_emiss(0.49, -9.0)).to be_within(epsilon).of 0.7549203
        expect(subject.sky_emiss(1.0, 3.0)).to be_within(epsilon).of 0.8363996
      end
    end

    context "when avg_v_press > 0.5" do
      it "should compute sky emissisivity correctly" do
        expect(subject.sky_emiss(30.0, 22.0)).to be_within(epsilon).of 3.5834687
      end
    end
  end

  describe ".angstrom" do
    it "should compute angstroms correctly" do
      expect(subject.angstrom(0.4, -11.0)).to be_within(epsilon).of 0.2058123
      expect(subject.angstrom(10.0, 5.0)).to be_within(epsilon).of -1.0955145
      expect(subject.angstrom(25.0, 25.0)).to be_within(epsilon).of -2.1072759
    end
  end

  describe ".clr_ratio" do
    it "should compute clr_ratio correctly" do
      expect(subject.clr_ratio(9.0, 45, 45.0)).to be_within(epsilon).of 0.6605110
      expect(subject.clr_ratio(20.0, 80, 30.0)).to be_within(epsilon).of 0.7649150
      expect(subject.clr_ratio(30.0, 200, 15.0)).to be_within(epsilon).of 0.9745485
      expect(subject.clr_ratio(40.0, 200, 15.0)).to eq 1.0
    end
  end

  describe ".lwnet" do
    it "should compute lwnet correctly" do
      expect(subject.lwnet(2.0, 22.0, 30.0, 200, 15.0)).to be_within(epsilon).of 2.4552792
      expect(subject.lwnet(0.4, 2.0, 9.0, 60, 45.0)).to be_within(epsilon).of 3.3314686
      expect(subject.lwnet(1.0, 17.0, 23.0, 120, 30.0)).to be_within(epsilon).of 3.9672827
    end
  end

  describe ".et" do
    it "should compute potential et correctly" do
      expect(subject.et(
        avg_temp: 22.0,
        avg_v_press: 2.0,
        insol: 30.0,
        day_of_year: 200,
        lat: 15.0)).to be_within(epsilon).of 0.2859975
      expect(subject.et(
        avg_temp: 2.0,
        avg_v_press: 0.4,
        insol: 9.0,
        day_of_year: 60,
        lat: 45.0)).to be_within(epsilon).of 0.0298425
      expect(subject.et(
        avg_temp: 17.0,
        avg_v_press: 1.0,
        insol: 23.0,
        day_of_year: 120,
        lat: 30.0)).to be_within(epsilon).of 0.173987
    end
  end

  describe ".et_adj (using experimental coefficients)" do
    # results will be different from non-adjusted et
    context "when avg_v_press > 0.5" do
      it "should compute potential et correctly" do
        expect(subject.et_adj(
          avg_temp: 22.0,
          avg_v_press: 2.0,
          insol: 30.0,
          day_of_year: 200,
          lat: 15.0)
        ).to be_within(epsilon).of 0.212872
        # non-adjusted: 0.2859975
        
        expect(subject.et_adj(
          avg_temp: 17.0,
          avg_v_press: 1.0,
          insol: 23.0,
          day_of_year: 120,
          lat: 30.0)
        ).to be_within(epsilon).of 0.124371
        # non-adjusted: 0.173987
      end
    end

    # result will be the same as non-adjusted et
    context "when avg_v_press <= 0.5" do
      it "should compute potential et correctly" do
        expect(subject.et_adj(
          avg_temp: 2.0,
          avg_v_press: 0.4,
          insol: 9.0,
          day_of_year: 60,
          lat: 45.0)
        ).to be_within(epsilon).of 0.0298425
        # non-adjusted: 0.0298425
      end
    end
  end
end
