# Agricultural Weather API

[![Circle CI](https://circleci.com/gh/uwent/ag-weather.svg?style=svg&circle-token=467dfd3ec0f5d33330548a6d939f94d52d3f07ec)](https://circleci.com/gh/uwent/ag-weather)

## Description

This project is to support the UW-Extension's Agricultural Weather Service.  Included are the tools to load weather and insolation data from remote sources, calculate and store daily evapotranspiration data, calculate multiple formulas of degreee days, generate and save state-wide maps to display this data, and provide access to all of this information through public endpoints.

## Dependencies

`Ruby 3.0.x`
```bash
# install rbenv
sudo apt -y install rbenv

# install ruby-build
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

# or update ruby-build if already installed
git -C "$(rbenv root)"/plugins/ruby-build pull

# install ruby with rbenv
rbenv install 3.0.3 # or latest version

# update bundler to latest
gem install bundler
```

`Postgres 12` and `gem pg`
```bash
# install postgres
sudo apt -y install postgresql-12 postgresql-client-12 libpq-dev
sudo service postgresql start

# install gem pg
gem install pg

# Set postgres user password to 'password'
sudo su - postgres
psql -c "alter user postgres with password 'password'"
exit
```

`Python` and `eccodes` for weather data [GRIB files](https://en.wikipedia.org/wiki/GRIB)
```bash
sudo apt -y install python3 python3-pip libeccodes-tools
pip install ecCodes
grib_get_data # confirm it works
```

`gnuplot` and `imagemagicks` for Insolation and Evapotranspiration map creation
```bash
sudo apt -y install gnuplot
gnuplot # confirm it works

sudo apt -y install imagemagick
composite # confirm it works
```

## Setup

1. Ensure dependencies above are satisfied
2. Clone the project
3. Install gems with `bundle install` in project directory
4. Create database and schema with `bundle exec rake db:setup`
5. Import and process weather data. By default it will fetch the last 5 days.
    * Open the rails console `bundle exec rails c`
    * Run all the data scripts with `RunTasks.all`
    * Exit the rails console with `exit`
6. Start the server with `bundle exec rails s`
7. Server will be listening on `localhost:8080`

## Running Tests

### Lint

```bash
# check code for style before commit
bundle exec standardrb --fix
```

### RSpec

```bash
bundle exec rspec
```

### API Documentation

```bash
bundle exec rake dredd RAILS_ENV=test
```

## Deployment

Work with db admin to authorize your ssh key for the deploy user. Confirm you can access the dev and production servers:

* `ssh deploy@dev.agweather.cals.wisc.edu -p 216`
* `ssh deploy@agweather.cals.wisc.edu -p 216`

Then run the following commands from the main branch to deploy:

* Staging: `cap staging deploy`
* Production: `cap production deploy`

## Endpoints

Endpoints are summarized in [our API Blueprint](apiary.apib) file.
