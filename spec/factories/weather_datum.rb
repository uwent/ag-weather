FactoryBot.define do
  factory :weather_datum do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
    min_temp { rand(0.0..10.0) }
    max_temp { rand(20.0..30.0) }
    min_rh { rand(0..50) }
    max_rh { rand(50..100) }
    vapor_pressure { rand(0.0..3.5) }
    hours_rh_over_90 { rand(0..24) }
    avg_temp_rh_over_90 { rand(10.0..20.0) }

    after :build do |t|
      t.avg_temp = (t.min_temp + t.max_temp) / 2.0 if t.min_temp && t.max_temp
      t.avg_rh = (t.min_rh + t.max_rh) / 2.0 if t.min_rh && t.max_rh
    end
  end
end
