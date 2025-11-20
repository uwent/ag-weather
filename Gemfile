source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "railties", "~> 8.0"
gem "activesupport", "~> 8.0"
gem "activerecord-import" # bulk import
gem "pg" # postgres
gem "rswag" # swagger api docs
gem "sassc-rails" # sass css
gem "httparty"
gem "net-ftp"
gem "json"
gem "whenever" # task scheduling
gem "tzinfo" # timezone
gem "csv"
gem "ostruct" # no longer a default gem as of 3.3.6
gem "rack-attack" # rate limiting

group :development do
  gem "puma"
  gem "pry-rails"
  gem "capistrano"
  gem "capistrano-rbenv"
  gem "capistrano-rails"
  gem "capistrano-bundler"
  gem "letter_opener"
  gem "letter_opener_web"
  gem "web-console"
  gem "standard" # linter
  gem "activerecord-analyze" # query analysis
  gem "brakeman" # security analysis https://brakemanscanner.org/
  gem "bundler-audit" # patch-level verification
  gem "ed25519" # for ssh keys
  gem "bcrypt_pbkdf" # for ssh keys
end

group :development, :test do
  gem "byebug"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "rspec_junit_formatter"
  gem "rspec-rails"
  gem "spring"
  gem "spring-commands-rspec"
end

group :test do
  gem "database_cleaner-active_record"
  gem "webmock"
  gem "simplecov"
end
