FactoryBot.define do
  factory :insolation do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
    insolation { rand(0.0..30.0) }
  end
end
