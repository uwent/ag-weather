FactoryBot.define do
  factory :pest_forecast do
    date { Date.yesterday }
    latitude { 45.0 }
    longitude { -89.0 }
    potato_blight_dsv { rand(0..4) }
    potato_p_days { rand(0.0..10.0) }
    carrot_foliar_dsv { rand(0..4) }
    cercospora_div { rand(0..7) }
    botcast_dsi { rand(0..2) }
  end
end
