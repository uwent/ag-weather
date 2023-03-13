FactoryBot.define do
  vals = 2.times.collect { |i| rand(280.0..300.0) }.sort
  factory :weather_observation do
    temperature { vals[1] }
    dew_point { vals[0] }
    initialize_with { new(temperature, dew_point) }
  end
end
