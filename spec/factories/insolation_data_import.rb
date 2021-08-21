FactoryBot.define do
  factory :insolation_data_import do
    readings_on { Date.yesterday }
    status { "successful" }
  end
end
