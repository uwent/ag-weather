class LandGrid
  # include Enumerable

  # EPSILON = 0.000001
  N_LAT = 50
  S_LAT = 38
  E_LONG = 82
  W_LONG = 98
  STEP = 0.1

  def extents
    {
      min_lat: 38,
      max_lat: 50,
      min_long: 82,
      max_long: 98,
      step: 0.1
    }
  end

  def initialize(
    # min_lat = S_LAT,
    # max_lat = N_LAT,
    # min_long = E_LONG,
    # max_long = W_LONG,
    # step = STEP
  )
    min_lat = extents[:min_lat]
    max_lat = extents[:max_lat]
    min_long = extents[:min_long]
    max_long = extents[:max_long]
    step = extents[:step]



    raise TypeError, "minimum latitude must be less than maximum latitude" if (min_lat >= max_lat)
    raise TypeError, "minimum longitude must be less than maximum longitude" if (min_long >= max_long)
    raise TypeError, "step must be greater than 0" if (step <= 0)
    raise TypeError, "step must be less than latitude difference and longitude difference" if (step > max_lat - min_lat || step > max_long - min_long)

    # @min_latitude = min_lat
    # @max_latitude = max_lat
    # @min_longitude = min_long
    # @max_longitude = max_long
    # @step = step
    @min_latitude = min_lat
    @max_latitude = max_lat
    @min_longitude = min_long
    @max_longitude = max_long
    @step = step
    @data = create_grid
  end

  def each(&block)
    @data.each do |row|
      row.each do |value|
        block.call(value)
      end
    end
  end

  # def self.weather_grid
  #   self.new(
  #     WeatherExtent::S_LAT,
  #     WeatherExtent::N_LAT,
  #     WeatherExtent::E_LONG,
  #     WeatherExtent::W_LONG,
  #     WeatherExtent::STEP
  #   )
  # end

  def latitudes
    @min_latitude..@max_latitude
  end

  def longitudes
    @min_longitude..@max_longitude
  end

  def inside?(lat, long)
    (latitudes === lat) && (longitudes === long)
  end

  def each_point
    latitudes.step(@step).each do |lat|
      longitudes.step(@step).each do |long|
        yield(lat, long)
      end
    end
  end

  def num_points
    latitudes.step(@step).count * longitudes.step(@step).count
  end

  def closest_point(lat, long)
    lat = @data.closest_point(lat)
    return lat, @data[lat].closest_point(long)
  end

  def [](lat, long)
    @data[lat][long]
  end

  def []=(lat, long, value)
    @data[lat][long] = value
  end

  private
    def create_grid
      data = RangeArray.new(@min_latitude, @max_latitude, @step)
      latitudes.step(@step) do |lat|
        data[lat] = RangeArray.new(@min_longitude, @max_longitude, @step)
      end
      return data
    end
end
