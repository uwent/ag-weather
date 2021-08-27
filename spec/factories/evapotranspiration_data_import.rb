FactoryBot.define do
  factory :evapotranspiration_data_import do
    readings_on { Date.yesterday }
    status { "successful" }
  end
end
