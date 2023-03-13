FactoryBot.define do
  factory :precip do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
    precip { rand(0.0..5.0) }
  end
end
