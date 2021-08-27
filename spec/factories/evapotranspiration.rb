FactoryBot.define do
  factory :evapotranspiration do
    latitude { 43.0 }
    longitude { -89.7 }
    date { Date.yesterday }
    potential_et { 0.17 }
  end
end
