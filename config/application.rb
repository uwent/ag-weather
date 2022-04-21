require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AgWeather
  class MessageFormatter < ActiveSupport::Logger::SimpleFormatter
    def call(severity, time, progname, msg)
      level = sprintf("%-5s", severity.to_s)
      time = time.strftime("%Y-%m-%d %H:%M:%S")
      msg = msg&.truncate(200, omission: "...#{msg.last(100)}")
      "#{level} [#{time}] #{msg}\n"
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths << Rails.root.join("app/models/data_imports")
    config.autoload_paths << Rails.root.join("app/models/data_importers")
    config.autoload_paths << Rails.root.join("app/models/land_extents")

    # Image generation and service configuration
    config.x.image.temp_directory = "tmp"
    config.x.image.base_dir = "public"
    config.x.image.url_path = ""

    config.log_formatter = MessageFormatter.new
  end
end
