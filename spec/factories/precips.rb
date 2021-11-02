FactoryBot.define do
  factory :precip do
    date { Date.yesterday }
    latitude { 43.0 }
    longitude { -89.7 }
    precip { 1.56 }
  end
end
