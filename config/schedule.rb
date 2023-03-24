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
set :env_path, '"$HOME/.rbenv/shims":"$HOME/.rbenv/bin"'
job_type :runner, ' cd :path && PATH=:env_path:"$PATH" bin/rails runner -e :environment ":task" :output '

# Daily data import task
every :day, at: ["6:00am"] do
  runner "RunTasks.daily"
end

# Clean up old (>1 month) map images
every :day do
  runner "RunTasks.purge_old_images(delete: true)"
end

# Station data is deprecated
# every "*/5 * * * *" do
#   runner "StationHourlyObservationImporter.check_for_file_and_load"
# end
