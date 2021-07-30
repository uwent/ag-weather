class WeatherDay
  attr_accessor :date, :data

  def initialize(date)
    @date = date
    @data = LandGrid.wi_mn_grid
    WiMn.each_point do |lat, long|
      @data[lat, long] = []
    end
  end

  def load_from(dirname)
    Dir["#{dirname}/*.grb2_wexp"].each do |filename|
      Rails.logger.info("WeatherDay :: Loading #{filename}")
      wh = WeatherHour.new()
      wh.load_from(filename)
      add_data_from_weather_hour(wh)
    end
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
    WiMn.each_point do |lat, long|
      @data[lat, long] <<
        WeatherObservation.new(
          hour.temperature_at(lat, long),
          hour.dew_point_at(lat, long))
    end
  end
end
