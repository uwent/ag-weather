require 'dredd/rack'

# Allow the automatic setup of a local application server when necessary
#
# Find the name of your application in its `config.ru` file.
Dredd::Rack.app = Rails.application
