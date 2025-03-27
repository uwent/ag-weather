class WeatherDay
  attr_accessor :data

  def initialize
    @data = {}
    LandExtent.each_point do |lat, lng|
      @data[[lat, lng]] = []
    end
  end

  def load_from(dirname)
    day_start = Time.current
    Rails.logger.info "WeatherDay :: Loading weather hour grib files from #{dirname}"
    files = Dir["#{dirname}/*.grb2_wexp"]
    files.each_with_index do |filename, i|
      hour_start = Time.current
      Rails.logger.info "WeatherDay :: Loading hour #{i}..."
      wh = WeatherHour.new
      wh.load_from(filename)
      add_data_from_weather_hour(wh)
      Rails.logger.info "WeatherDay :: Processed hour #{i} in #{DataImporter.elapsed(hour_start)}"
    end
    Rails.logger.info "WeatherDay :: Loading weather hours completed in #{DataImporter.elapsed(day_start)}"
  end

  # assumes the data passed in is in Kelvin
  def add_data_from_weather_hour(wh)
    LandExtent.each_point do |lat, lng|
      temp = wh.temperature_at(lat, lng)
      dew_point = wh.dew_point_at(lat, lng)
      @data[[lat, lng]] << WeatherObservation.new(temp, dew_point)
    end
  end

  def observations_at(lat, lng)
    @data[[lat, lng]]
  end
end
