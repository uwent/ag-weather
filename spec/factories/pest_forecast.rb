FactoryBot.define do
  factory :pest_forecast do
    date { Date.current }
    latitude { 45.0 }
    longitude { 90.0 }
    potato_blight_dsv { rand(4) }
    potato_p_days { rand(8) }
    dd_50_86 { rand(100) }
  end
end
