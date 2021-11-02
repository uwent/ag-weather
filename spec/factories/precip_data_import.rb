FactoryBot.define do
  factory :precip_data_import do
    readings_on { Date.yesterday }
    status { "successful" }
  end
end
