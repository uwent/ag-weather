require "rails_helper"

def build_weather(**args)
  FactoryBot.build(:weather, **args)
end

RSpec.describe PestModels do
  subject { Class.new { extend PestModels } }

  describe ".compute_potato_p_days" do
    context "temp < 7" do
      it "calculates correctly" do
        @weather = build_weather(min_temp: 0, max_temp: 5)
        pday = subject.compute_potato_p_days(@weather).round(2)
        expect(pday).to eq 0
      end
    end

    context "temp between 7 & 21" do
      it "calculates correctly" do
        @weather = build_weather(min_temp: 10, max_temp: 15)
        pday = subject.compute_potato_p_days(@weather).round(2)
        expect(pday).to eq 5.46
      end
    end

    context "temp between 21 & 30" do
      it "calculates correctly" do
        @weather = build_weather(min_temp: 25, max_temp: 30)
        pday = subject.compute_potato_p_days(@weather).round(2)
        expect(pday).to eq 5.81
      end
    end

    context "temp > 30" do
      it "calculates correctly" do
        @weather = build_weather(min_temp: 35, max_temp: 40)
        pday = subject.compute_potato_p_days(@weather).round(2)
        expect(pday).to eq 0
      end
    end

    context "invalid data" do
      it "defaults to 0 on missing temperatures" do
        @weather = build_weather(min_temp: nil, max_temp: nil)
        expect(subject.compute_potato_p_days(@weather)).to eq 0
      end
    end
  end

  describe ".compute_late_blight_dsv" do
    # temp, hours, output
    inputs = {
      [5, nil] => 0, # nil hours
      [5, 0] => 0, # 0 hours rh
      [5, 10] => 0,
      [10, 17] => 1,
      [10, 24] => 3,
      [15, 14] => 1,
      [15, 20] => 3,
      [20, 10] => 1,
      [20, 20] => 4
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        @weather = build_weather(avg_temp_rh_over_90: args[0], hours_rh_over_90: args[1])
        expect(subject.compute_late_blight_dsv(@weather)).to eq val
      end
    end
  end

  describe ".compute_carrot_foliar_dsv" do
    # temp, hours, output
    inputs = {
      [5, nil] => 0, # nil hours
      [5, 0] => 0, # 0 hours rh
      [5, 10] => 0,
      [15, 5] => 0,
      [15, 10] => 1,
      [15, 24] => 3,
      [20, 5] => 1,
      [20, 20] => 3,
      [25, 5] => 1,
      [25, 15] => 3,
      [30, 10] => 2,
      [30, 24] => 4
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        @weather = build_weather(avg_temp_rh_over_90: args[0], hours_rh_over_90: args[1])
        expect(subject.compute_carrot_foliar_dsv(@weather)).to eq val
      end
    end
  end

  describe ".compute_cercospora_div" do
    # temp, hours, output. Temps in F here.
    inputs = {
      [50, nil] => 0, # nil hours
      [50, 0] => 0, # 0 hours rh
      [50, 10] => 0,
      [60, 24] => 1,
      [65, 10] => 2,
      [65, 18] => 3,
      [70, 5] => 1,
      [70, 15] => 4,
      [72, 20] => 5,
      [73, 20] => 6,
      [75, 5] => 1,
      [75, 20] => 6,
      [77, 22] => 6,
      [78, 20] => 6,
      [79, 20] => 7,
      [80, 8] => 3,
      [80, 14] => 6,
      [90, 8] => 5
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        temp = UnitConverter.f_to_c(args[0])
        @weather = build_weather(avg_temp_rh_over_90: temp, hours_rh_over_90: args[1])
        expect(subject.compute_cercospora_div(@weather)).to eq val
      end
    end
  end

  describe ".botrytis_pmi" do
    let(:epsilon) { 1e-10 }
    # temp, hours, output
    inputs = {
      [5, 0] => 0,
      [10, 5] => 0,
      [15, 15] => 1.78629e-5,
      [20, 20] => 9.37190e-6,
      [25, 15] => 6.06976e-7,
      [30, 20] => 3.18234e-7
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        expect(subject.botrytis_pmi(*args)).to be_within(epsilon).of val
      end
    end
  end

  describe ".compute_botcast_dsi" do
    # temp, hours, output
    inputs = {
      [5, 0] => 0,
      [10, 5] => 0,
      [15, 15] => 2,
      [20, 20] => 2,
      [25, 15] => 2,
      [30, 20] => 0
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        @weather = build_weather(avg_temp_rh_over_90: args[0], hours_rh_over_90: args[1])
        expect(subject.compute_botcast_dsi(@weather)).to eq val
      end
    end
  end

  describe ".botcast_dinfv" do
    # temp, output
    inputs = {
      [5, 5] => 0,
      [15, 5] => 0,
      [25, 5] => 0,
      [7, 14] => 1,
      [12, 8] => 0,
      [15, 9] => 1,
      [21, 10] => 1,
      [10, 18] => 2,
      [15, 20] => 2,
      [20, 20] => 2,
      [27, 20] => 1,
      [30, 10] => 0
    }

    inputs.each do |args, val|
      it "returns #{val} given temp #{args[0]} and hours #{args[1]}" do
        expect(subject.botcast_dinfv(*args)).to eq val
      end
    end
  end
end
