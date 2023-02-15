source "https://rubygems.org"

gem "rails", "~> 7.0"
gem "railties", "~> 7.0"
gem "activesupport", "~> 7.0"
gem "pg", "~> 1.3"
gem "activerecord-import", "~> 1.4"
gem "agwx_biophys", "0.0.4"
gem "httparty", "~> 0.20"
gem "jbuilder", "~> 2.11"
gem "json", "~> 2.6"
gem "sassc-rails", "~> 2.1"
gem "whenever", "~> 1.0"
gem "tzinfo", "~> 2.0"
gem "activerecord-analyze" # query analysis

group :development do
  gem "puma", "~> 5" # puma 6 breaks dredd-rack API testing, keep 5.x for now.
  gem "capistrano"
  gem "capistrano-rbenv"
  gem "capistrano-rails"
  gem "capistrano-bundler"
  gem "letter_opener"
  gem "letter_opener_web"
  gem "web-console"
  gem "standard"
  gem "compact_log_formatter"
end

group :development, :test do
  gem "byebug"
  gem "dredd-rack"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "pry-rails"
  gem "rspec_junit_formatter"
  gem "rspec-rails"
  gem "spring"
  gem "spring-commands-rspec"
end

group :test do
  gem "webmock"
  gem "simplecov"
end
