== README

= Endpoints

** Insolation
  * #show (insolations/2016-01-07)
    - returns a hash** of paths to insolation maps of the east and west halves of the US on the given date.
** Evapotranspiration
  * #show (evapotranspirations/2016-01-07)
    - returns a path to an ET map of the greater Wisconsin area
  * #index (evapotranspirations?lat=42.8&long=270.423&start_date=2016-01-01&end_date=2016-01-07&format=json
    - returns data from DB for the coordinates listed through the dates listed in the format given
** Degree Days
  * #show (degree_days/2016-01-07?map=1)**
    - returns a path to a map of the degree days for certain conditions
  * #index (degree_days?method=sine&base=45&upper=86&start_date=2016-01-01&end_date=2016-01-07&lat=43.21&long=271.67&format=text)
    - calculates and returns data meeting the specified parameters


This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.
