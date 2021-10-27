FactoryBot.define do
  factory :weather_data_import do
    readings_on { Date.yesterday }
    status { "successful" }
  end
end