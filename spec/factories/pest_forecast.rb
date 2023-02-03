FactoryBot.define do
  factory :pest_forecast do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -90.0 }
    potato_blight_dsv { rand(4) }
    potato_p_days { rand(8) }
    dd_32_none { rand(100) }
    dd_50_86 { rand(100) }
    freeze { true }
  end
end
