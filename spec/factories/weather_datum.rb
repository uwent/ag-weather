FactoryBot.define do
  factory :weather_datum do
    latitude { 43.0 }
    longitude { -89.7 }
    date { Date.yesterday }
    max_temperature { 12.5 }
    min_temperature { 8.9 }
    avg_temperature { 10.7 }
    vapor_pressure  { 1.6 }
  end
end
