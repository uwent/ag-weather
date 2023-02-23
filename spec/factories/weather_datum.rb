FactoryBot.define do
  factory :weather_datum do
    latitude { 43.0 }
    longitude { -89.7 }
    date { Date.yesterday }
    max_temp { 12.5 }
    min_temp { 8.9 }
    avg_temp { 10.7 }
    min_rh { 10.0 }
    avg_rh { 50.0 }
    max_rh { 75.0 }
    vapor_pressure { 1.6 }
    hours_rh_over_90 { 4 }
    avg_temp_rh_over_90 { 15 }
  end
end
