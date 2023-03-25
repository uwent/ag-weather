require "open3"

class WeatherHour
  attr_reader :data

  def initialize
    @data = {}
    LandExtent.each_point do |lat, long|
      @data[[lat, long]] = {
        temperatures: [],
        dew_points: []
      }
    end
  end

  # processes hourly weather grib files and pulls temperatures and dew points
  def load_from(filename)
    start_time = Time.current
    cmd = "grib_get_data -w shortName=2t/2d -p shortName #{filename}"
    Rails.logger.debug "RTMA grib cmd >> #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)
    stdout.each do |line|
      lat, long, value, type = line.split
      long = long.to_f - 360.0
      store(lat, long, value, type)
    end
    Rails.logger.debug "WeatherHour :: Grib file read in #{DataImporter.elapsed(start_time)}"
  end

  def store(lat, long, value, type)
    return if value.nil?
    return unless key = data_key(type)
    lat = lat.to_f.round(1)
    long = long.to_f.round(1)
    return unless @data[[lat, long]]
    @data[[lat, long]][key] << value.to_f
  end

  def data_key(type)
    return :temperatures if type == "2t"
    return :dew_points if type == "2d"
  end

  # averages all temperatures assigned to the lat/long cell
  def temperature_at(lat, long)
    vals = @data[[lat, long]][:temperatures]
    (vals.size > 0) ? vals.sum(0.0) / vals.size : nil
  end

  # averages all dewpoints assigned to the lat/long cell
  def dew_point_at(lat, long)
    vals = @data[[lat, long]][:dew_points]
    (vals.size > 0) ? vals.sum(0.0) / vals.size : nil
  end
end
