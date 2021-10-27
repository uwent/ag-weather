require "open3"

class WeatherHour
  attr_reader :data

  def initialize()
    @data = LandGrid.new
    LandExtent.each_point do |lat, long|
      @data[lat, long] = {
        temperatures: [],
        dew_points: []
      }
    end
  end

  def data_key(data_type)
    return :dew_points if data_type == "2d"
    return :temperatures if data_type == "2t"
  end

  def store(type, lat, long, data)
    lat, long = lat.round(1), long.round(1)
    @data[lat, long][data_key(type)] << data
  end

  def load_from(filename)
    grib_start = Time.current

    cmd = "grib_get_data -w shortName=2t/2d -p shortName #{filename}"
    Rails.logger.debug ">> grib cmd: #{cmd}"
    _, stdout, _ = Open3.popen3(cmd)

    stdout.each do |line|
      lat, long, data, type = line.split
      lat = lat.to_f
      long = long.to_f - 360.0
      data = data.to_f
      store(type, lat, long, data) if LandExtent.inside?(lat, long)
    end

    Rails.logger.debug ">> Grib file read in #{Time.current - grib_start} seconds"
  end

  def temperature_at(lat, long)
    temps = @data[lat, long][:temperatures]
    if temps.size > 0
      return temps.sum(0.0) / temps.size
    else
      Rails.logger.warn "WeatherHour :: Missing temperature data for [#{lat}, #{long}]"
      return nil
    end
  end

  def dew_point_at(lat, long)
    dewpts = @data[lat, long][:dew_points]
    if dewpts.size > 0
      return dewpts.sum(0.0) / dewpts.size
    else
      Rails.logger.warn "WeatherHour :: Missing dewpoint data for [#{lat}, #{long}]"
      return nil
    end
  end
end
