FactoryBot.define do
  factory :degree_day do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
  end
end
