begin
  WebMock.allow_net_connect! if defined?(WebMock)

  require 'dredd/rack'

  Dredd::Rack::RakeTask.new do |task|
    task.runner.configure do |dredd|
      dredd.paths_to_blueprints 'apiary.apib'
      dredd.language 'ruby'
    end
  end

  task fixtures: [:environment] do
    fail 'Only allowed for test' unless Rails.env.test?
  end

  task dredd: [:environment, :fixtures]
rescue LoadError
end
