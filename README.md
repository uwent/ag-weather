# Agricultural Weather API 
[[Circle CI](url)](https://circleci.com/gh/adorableio/ag-weather)

## Daily Process

Early every morning we will run a sequence of steps:
* Save NOAA grib files locally (`WeatherFetcher.fetch`)
* Load weather data from grib files into DB (`WeatherImporter.import`)
* Load insolation data from SSEC server into DB (`InsolationImporter.fetch`)
* Calculate ET data and save to DB (`EvapotranspirationImporter.create_et_data`)
* Generate map images for insolation, ET, and different degree day formulas (???)

## Endpoints

### Insolation

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

### Endpoint Testing

    RAILS_ENV=test bundle exec rake dredd
