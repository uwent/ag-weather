FactoryBot.define do
  factory :evapotranspiration do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
    potential_et { rand(0.0..0.3) }
  end
end
