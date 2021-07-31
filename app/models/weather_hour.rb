require 'open3'

class WeatherHour
  attr_reader :data

  def initialize()
    @data = LandGrid.weather_grid
      
    WeatherExtent.each_point do |lat, long|
      @data[lat, long] = {
        temperatures: [],
        dew_points: []
      }
    end
  end

  def data_key(data_type)
    return :dew_points if data_type == '2d'
    return :temperatures if data_type == '2t'
  end

  def store(data_type, lat, long, value)
    key = data_key(data_type)
    closest_lat, closest_long = @data.closest_point(lat, long)
    @data[closest_lat, closest_long][key] << Reading.new(lat, long, value)
  end

  def load_from(filename)
    cmd = "grib_get_data -w shortName=2t/2d -p shortName #{filename}"
    _, stdout, _ = Open3.popen3(cmd)
    stdout.each do |line|
      (lat, long, data, type) = line.split
      if WeatherExtent.inside?(lat.to_f, 360.0 - long.to_f)
        store(type, lat.to_f, 360.0 - long.to_f, data.to_f)
      end
    end
  end

  def closest(lat, long, arr)
    arr.min_by { |pt| pt.distance(lat, long) }
  end

  def temperature_at(lat, long)
    reading = closest(lat, long, @data[lat, long][:temperatures])
    reading && reading.value
  end

  def dew_point_at(lat, long)
    reading = closest(lat, long, @data[lat, long][:dew_points])
    reading && reading.value
  end
end
