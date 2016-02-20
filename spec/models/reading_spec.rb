require "rails_helper"

RSpec.describe Reading  do

  context "initialize" do
    it "can make a reading " do
      reading = Reading.new(10, 20, 0.1)
      expect(reading).to be_truthy
    end
  end

  context "attributes" do
    let (:reading) { Reading.new(50, 45, 17.0) }
    
    it 'can read latitude' do
      expect(reading.latitude).to eq 50
    end

    it 'can write latitude' do
      reading.latitude = 20
      expect(reading.latitude).to eq 20
    end

    it 'can read longitude' do
      expect(reading.longitude).to eq 45
    end

    it 'can write longitude' do
      reading.longitude = 15
      expect(reading.longitude).to eq 15
    end

    it 'can read value' do
      expect(reading.value).to eq 17.0
    end

    it 'can write value' do
      reading.value = 34.5
      expect(reading.value).to eq 34.5
    end
  end

  context "distance to other point" do
    let (:reading) { Reading.new(10, 25, 17.9) }

    it 'can compute the distance in km from another point' do
      expect(reading.distance(10.1, 25.1).round(2)).to eq 15.61
    end
  end

  it "has a to_s defined" do
    reading = Reading.new(10, 25, 17.9)
    expect(reading.to_s).to eq '(10, 25): 17.9'
  end
end
