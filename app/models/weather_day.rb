require 'open3'
class WeatherDay 

  def initialize()
    @data = {
      pressure: LandGrid.new(WiMn::S_LAT, WiMn::N_LAT, WiMn::E_LONG, 
                             WiMn::W_LONG, WiMn::STEP),
      temperature: LandGrid.new(WiMn::S_LAT, WiMn::N_LAT, WiMn::E_LONG, 
                                WiMn::W_LONG, WiMn::STEP)
    }
    WiMn.each_point do |lat, long| 
      temp_data[lat, long] = []
      pressure_data[lat, long] = []
    end
  end

  def temp_data 
    @data[:temperature]
  end

  def pressure_data
    @data[:pressure]
  end

  def grid_for_key(data_type)
    return pressure_data if data_type == 'sp'
    return temp_data if data_type == '2t'
  end

  def store(data_type, lat, long, value)
    land_grid = grid_for_key(data_type)
    closest_lat = land_grid.closest_latitude(lat)
    closest_long = land_grid.closest_longitude(long)
    land_grid[closest_lat, closest_long] << Reading.new(lat, long, value)
  end

  def load_from(filename)
    cmd = "grib_get_data -w shortName=2t/sp -p shortName #{filename}"
    _, stdout, _ = Open3.popen3(cmd)
    stdout.each do |line| 
      (lat, long, data, type) = line.split
      store(type, lat.to_f, 360.0 - long.to_f, data.to_f) if 
        WiMn.inside_wi_mn_box?(lat.to_f, 360.0 - long.to_f)
    end
  end

  def closest(lat, long, arr)
    arr.min_by { |pt| pt.distance(lat, long) }
  end

  def temperature_at(lat, long)
    closest(lat, long, temp_data[lat, long])
  end

  def pressure_at(lat, long)
    closest(lat, long, pressure_data[lat, long])
  end
end
