# Agricultural Weather API 
[![Circle CI](https://circleci.com/gh/adorableio/ag-weather.svg?style=svg)](https://circleci.com/gh/adorableio/ag-weather)

## Description
This project is to support the UW-Extension's Agricultural Weather Service.  Included are the tools to load weather and insolation data from remote sources, calculate and store daily evapotranspiration data, calculate multiple formulas of degreee days, generate and save state-wide maps to display this data, and provide access to all of this information through public endpoints.

## Setup
* clone the project
* Install dependencies
```
bundle install
```
* Create database and schema
```
bundle exec rake db:create db:migrate
```
* Import data (This will take a looooong time; probably several hours)
  * open the rails console `bundle exec rails c`
  * follow the steps in parantheses in the Daily Process section

* Start server
```
rails s
```


## Daily Process

Early every morning we will run a sequence of steps:
* Save NOAA grib files locally (`WeatherFetcher.fetch`)
* Load weather data from grib files into DB (`WeatherImporter.import`)
* Load insolation data from SSEC server into DB (`InsolationImporter.fetch`)
* Calculate ET data and save to DB (`EvapotranspirationImporter.create_et_data`)
* Generate map images for insolation, ET, and different degree day formulas (???)

## Endpoints

### Insolation
The following is a summary of this project's API. For full documentation, see [our API Blueprint](apiary.apib).

#### - Show
    GET /insolations/:date
Will return a JSON object with the path to images of both east and west halves of the US.

### Evapotranspiration

#### - Show
    GET  /evapotranspirations/:date
Will return a JSON object containing the path to an image of a map for ET estimates across Wisconsin and Minnesota.

#### - Index
    GET  /evapotranspirations{?lat& long& start_date& end_date}
Will return a JSON object with ET data for the point specified for every day in the range specified.

### Degree Days

#### - Show
    GET /degree_days/:date
Will return a JSON object with paths to the maps for all the different Degree Day maps that are currently supported for that date

#### - Index
    GET /degree_days{?lat& long& start_date& end_date& formula& lower_bound& (upper_bound)}
Will return a JSON object with the total degree days for the input parameters

### Testing

#### - RSpec
```
bundle exec rspec
```
#### - Endpoints
```
RAILS_ENV=test bundle exec rake dredd
```
