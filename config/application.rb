require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module AgWeather
  class Application < Rails::Application
    config.load_defaults 6.0
    config.x.image.temp_directory = 'tmp'
    config.x.image.file_dir = 'public'
    config.x.image.url_path = ''
  end
end
