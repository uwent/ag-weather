require "open3"

class WeatherHour
  attr_reader :data

  def initialize
    @data = LandGrid.new
    LandExtent.each_point do |lat, long|
      @data[lat, long] = {
        temperatures: [],
        dew_points: []
      }
    end
  end

  def data_key(type)
    return :dew_points if type == "2d"
    return :temperatures if type == "2t"
  end

  def store(lat, long, value, type)
    lat = lat.round(1)
    long = long.round(1)
    @data[lat, long][data_key(type)] << value
  end

  # processes hourly weather grib files and pulls temperatures and dewpoints
  def load_from(filename)
    grib_start = Time.current

    cmd = "grib_get_data -w shortName=2t/2d -p shortName #{filename}"
    Rails.logger.debug "RTMA grib cmd >> #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)

    stdout.each do |line|
      lat, long, value, type = line.split
      lat = lat.to_f
      long = long.to_f - 360.0
      value = value.to_f
      store(lat, long, value, type) if LandExtent.inside?(lat, long)
    end

    Rails.logger.debug "WeatherHour :: Grib file read in #{(Time.current - grib_start).to_i} seconds"
  end

  # averages all temperatures assigned to the lat/long cell
  def temperature_at(lat, long)
    temps = @data[lat, long][:temperatures]
    temps.size > 0 ? temps.sum(0.0) / temps.size : nil
  end

  # averages all dewpoints assigned to the lat/long cell
  def dew_point_at(lat, long)
    dewpts = @data[lat, long][:dew_points]
    dewpts.size > 0 ? dewpts.sum(0.0) / dewpts.size : nil
  end
end
