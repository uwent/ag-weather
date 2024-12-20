require "swagger_helper"

# RSpec.describe 'weather', type: :request do

#   path '/index' do
#     get 'Returns weather data for lat, lng, date range' do
#       produces 'application/json'
#       parameter name: :lat, in: :query, type: :number
#       parameter name: :lng, in: :query, type: :number
#       parameter name: :start_date, in: :query, type: :string, format: :date, required: false
#       parameter name: :date, in: :query, type: :string, format: :date, required: false
#       parameter name: :end_date, in: :query, type: :string, format: :date, required: false

#       response '200', 'success' do
#         schema type: :object, properties: {
#           info: {
#             type: :object,
#             properties: {
#               status: { type: :string },
#               lat: { type: :number },
#               long: { type: :number },
#               start_date: {type: :string, format: :date},
#               end_date: {type: :string, format: :date},
#               days_requested: {type: :number},
#               days_returned: {type: :number},
#               units: {type: :object, properties: {
#                 temp: {type: :string},
#                 pressure: {type: :string},
#                 rh: {type: :string}
#               }},
#               compute_time: {type: :number}
#             }
#           },
#           data: {
#             type: :array, items: {
#               type: :object,
#               properties: {
#                 date: {type: :string, format: :date},
#                 min_temp: {type: :number},
#                 max_temp:  {type: :number},
#                 avg_temp:  {type: :number},
#                 dew_point:  {type: :number},
#                 vapor_pressure:  {type: :number},
#                 min_rh:  {type: :number},
#                 max_rh: {type: :number},
#                 avg_rh:  {type: :number},
#                 hours_rh_over_90:  {type: :integer},
#                 avg_temp_rh_over_90: {type: :number, nullable: true},
#                 frost: {type: :boolean},
#                 freezing: {type: :boolean}
#               }
#             }
#           },
#           required: [:info, :data]
#         }
#       end

#       # let(:lat) { 45.1 }
#       # let(:long) { -89.2 }
#       run_test! lat: 45.1, long: -89.2
#     end
#   end
# end
