FactoryBot.define do
  factory :insolation do
    latitude { 43.0 }
    longitude { 89.7 }
    date { Date.yesterday }
    insolation { 27 }
  end
end
