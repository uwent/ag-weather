class WeatherDay 
  attr_accessor :date, :data

  def initialize(date)
    @date = date
    @data = LandGrid.new(WiMn::S_LAT, WiMn::N_LAT, WiMn::E_LONG, WiMn::W_LONG,
                         WiMn::STEP)
    WiMn.each_point do |lat, long|
      @data[lat, long] = {
        temperatures: [],
        dew_points: []
      }
    end
  end

  def load_from(dirname)
    Dir["#{dirname}/*.grb2"].each do |filename|
      Rails.logger.info("WeatherDay :: Loading #{filename}")
      wh = WeatherHour.new()
      wh.load_from(filename)
      add_data_from_weather_hour(wh)
    end
  end

  def temperatures_at(lat, long)
    @data[lat,long][:temperatures]
  end

  def dew_points_at(lat, long)
    @data[lat,long][:dew_points]
  end

  def add_data_from_weather_hour(hour)
    WiMn.each_point do |lat, long|
      temperatures_at(lat, long) << hour.temperature_at(lat, long)
      dew_points_at(lat,long) << hour.dew_point_at(lat, long)
    end
  end
end
