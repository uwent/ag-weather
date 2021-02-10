# Agricultural Weather API
[![Circle CI](https://circleci.com/gh/adorableio/ag-weather.svg?style=svg&circle-token=467dfd3ec0f5d33330548a6d939f94d52d3f07ec)](https://circleci.com/gh/adorableio/ag-weather)

## Description
This project is to support the UW-Extension's Agricultural Weather Service.  Included are the tools to load weather and insolation data from remote sources, calculate and store daily evapotranspiration data, calculate multiple formulas of degreee days, generate and save state-wide maps to display this data, and provide access to all of this information through public endpoints.

Ruby version `2.6.5`

Rails version `6.1.2`

ecCodes for [GRIB files](https://en.wikipedia.org/wiki/GRIB)

## Setup
1. Install [ecCodes](https://github.com/ecmwf/eccodes) with pip or use Homebrew `brew install eccodes`
2. clone the project
3. Install dependencies
```
bundle install
```
4. Create database and schema
```
bundle exec rake db:create db:migrate
```
5. Import data. Default settings limit data fetch to a maximum of three days. **DAYS_BACK_WINDOW** constant set in models/data_import.rb. Importing 3 days will take ~ 20-30 minutes.
  * open the rails console `bundle exec rails c`
  * follow the steps in parentheses in the Daily Process section

6. Start server
```
bundle exec rails s
```

## Deployment
Work with db admin to authorize your ssh key for the deploy user, then run the following commands from the master branch:

Staging:
```
cap staging deploy
```
Production:
```
cap production deploy
```

## Daily Process

Early every morning, the following jobs are run for staging and production. For local data, run commands manually in the rails console. Default settings will fetch max previous 3 days of data:
* Load weather data from grib files into DB (`WeatherImporter.fetch`)
* Load insolation data from SSEC server into DB (`InsolationImporter.fetch`)
* Calculate ET data and save to DB (`EvapotranspirationImporter.create_et_data`)
* Calculate Pest data and save to DB (`PestForecastImporter.create_forecast_data`)
* Create static Evapotranspiration image(`Evapotranspiration.create_and_static_link_image`)
* Import Station Observation File (`StationHourlyObservationImporter.check_for_file_and_load`)


## Endpoints

### Insolation
The following is a summary of this project's API. For full documentation, see [our API Blueprint](apiary.apib).

#### Show
    GET /insolations/:date
Will return a JSON object with the path to images of both east and west halves of the US.

### Evapotranspiration

#### Show
    GET  /evapotranspirations/:date
Will return a JSON object containing the path to an image of a map for ET estimates across Wisconsin and Minnesota.

#### Index
    GET  /evapotranspirations{?lat& long& start_date& end_date}
Will return a JSON object with ET data for the point specified for every day in the range specified.

### Degree Days

#### Show
    GET /degree_days/:date
Will return a JSON object with paths to the maps for all the different Degree Day maps that are currently supported for that date

#### Index
    GET /degree_days{?lat& long& start_date& end_date& formula& lower_bound& (upper_bound)}
Will return a JSON object with the total degree days for the input parameters

### Running Tests

#### RSpec
```
bundle exec rspec
```
#### API Documentation
```
RAILS_ENV=test bundle exec rake dredd
```
