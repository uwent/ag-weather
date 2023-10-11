require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AgWeather
  class MessageFormatter < ActiveSupport::Logger::SimpleFormatter
    PAL = {
      black: "\u001b[30m",
      red: "\u001b[31m",
      green: "\u001b[32m",
      yellow: "\u001b[33m",
      blue: "\u001b[34m",
      magenta: "\u001b[35m",
      cyan: "\u001b[36m",
      white: "\u001b[37m",
      reset: "\u001b[0m"
    }

    SEV = {
      debug: "DBG",
      info: "NFO",
      warn: "WRN",
      error: "ERR",
      fatal: "FTL",
      unknown: "UNK"
    }

    CLR = {
      debug: PAL[:green],
      info: PAL[:white],
      warn: PAL[:yellow],
      error: PAL[:red],
      fatal: PAL[:red]
    }

    def call(severity, time, progname, msg)
      sev = severity.to_sym.downcase
      time = time.strftime("%Y-%m-%d %H:%M:%S")
      msg = msg&.truncate(500, omission: "...")
      "#{time} #{CLR[sev]}[#{SEV[sev]}] #{msg}#{PAL[:reset]}\n"
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"

    # config.eager_load = true
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
