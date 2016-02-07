require "rails_helper"

RSpec.describe Reading  do

  context "initialize" do
    it "can make a reading " do
      reading = Reading.new(10, 20, .1)
      expect(grid).to be_truthy
    end
  end

  context "attributes" do
    let (:reading) { Reading.new(50, 45, 17.0) }
    
    it 'can read latitude' do
      expect(reading.latitude).to eql 50
    end
    
  end

  context "distance to other point" do
    let (:reading) { Reading.new(10, 25, 17.9) }
  end
  
end
