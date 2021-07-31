class WeatherDay
  attr_accessor :date, :data

  def initialize(date)
    @data = LandGrid.weather_grid
    @date = date
    WeatherExtent.each_point do |lat, long|
      @data[lat, long] = []
    end
  end

  def load_from(dirname)
    Dir["#{dirname}/*.grb2_wexp"].each do |filename|
      Rails.logger.info("WeatherDay :: Loading #{filename}")
      wh = WeatherHour.new(@data)
      wh.load_from(filename)
      add_data_from_weather_hour(wh)
    end
  end

  def observations_at(lat, long)
    @data[lat, long]
  end

  def temperatures_at(lat, long)
    @data[lat, long].map(&:temperature)
  end

  def dew_points_at(lat, long)
    @data[lat, long].map(&:dew_point)
  end

  def add_data_from_weather_hour(hour)
    WeatherExtent.each_point do |lat, long|
      wo = WeatherObservation.new(
        hour.temperature_at(lat, long),
        hour.dew_point_at(lat, long)
      )
      puts @data[lat, long]
      @data[lat, long] << wo
    end
  end
end
