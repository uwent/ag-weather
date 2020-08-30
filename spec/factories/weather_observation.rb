FactoryBot.define do
  factory :weather_observation do
    temperature { 290.15 }
    dew_point { 290.15 }

    initialize_with { new(temperature, dew_point) }
  end
end
