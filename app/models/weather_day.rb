class WeatherDay
  attr_accessor :date, :data

  def initialize(date)
    @date = date
    @data = LandGrid.new
    LandExtent.each_point do |lat, long|
      @data[lat, long] = []
    end
  end

  def load_from(dirname)
    day_start = Time.current
    Rails.logger.info "WeatherDay :: Loading weather hours from #{dirname}"
    Dir["#{dirname}/*.grb2_wexp"].each_with_index do |filename, i|
      hour_start = Time.current
      wh = WeatherHour.new()
      wh.load_from(filename)
      Rails.logger.info "-> Grib file processed in #{(Time.current - hour_start).to_i} seconds"
      add_data_from_weather_hour(wh)
      Rails.logger.info "-> Loaded hour #{i} in #{(Time.current - hour_start).to_i} seconds"
    end
    Rails.logger.info "WeatherDay :: Loading weather hours completed in #{(Time.current - day_start).to_i} seconds"
  end

  def observations_at(lat, long)
    @data[lat, long]
  end

  def temperatures_at(lat, long)
    @data[lat,long].map(&:temperature)
  end

  def dew_points_at(lat, long)
    @data[lat,long].map(&:dew_point)
  end

  def add_data_from_weather_hour(hour)
    LandExtent.each_point do |lat, long|
      @data[lat, long] <<
        WeatherObservation.new(
          hour.temperature_at(lat, long),
          hour.dew_point_at(lat, long))
    end
  end
end
