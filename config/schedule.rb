# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
set :output, "/tmp/whenever.log"
set :env_path,    '"$HOME/.rbenv/shims":"$HOME/.rbenv/bin"'
job_type :runner, %q{ cd :path && PATH=:env_path:"$PATH" bin/rails runner -e :environment ':task' :output }

every :day, at: '5am' do
  runner "InsolationImporter.fetch"
end

every :day, at: '6am' do # seems the earliest all the data for the day is there
  runner "WeatherImporter.fetch"
end

every :day, at: '6:30am' do
  runner "EvapotranspirationImporter.create_et_data"
end

every :day, at: '6:31am' do
  runner "PestForecastImporter.create_forecast_data"
end

every :day, at: '6:35am' do
  runner "Evapotranspiration.create_and_static_link_image"
end
