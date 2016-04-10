class LandGrid
  include Enumerable

  EPSILON = 0.000001

  def each(&block)
    @data.each do |row|
      row.each do |value|
        block.call(value)
      end
    end
  end

  def self.number_of_points(min, max, step)
    1 + ((max - min) / step).round(6).floor
  end

  def self.wi_mn_grid
    self.new(WiMn::S_LAT, WiMn::N_LAT, WiMn::E_LONG, WiMn::W_LONG, WiMn::STEP)
  end

  def initialize(min_lat, max_lat, min_long, max_long, step)
    raise TypeError, "minimum latitude must be less than maximum latitude" if (min_lat >= max_lat)
    raise TypeError, "minimum longitude must be less than maximum longitude" if (min_long >= max_long)
    raise TypeError, "step must be greater than 0" if (step <= 0)
    raise TypeError, "step must be less than latitude difference and longitude difference" if (step > max_lat - min_lat || step > max_long - min_long)

    @min_latitude = min_lat
    @max_latitude = max_lat
    @min_longitude = min_long
    @max_longitude = max_long
    @step = step
    @data = create_grid
  end

  def closest_point(lat, long)
    lat  = @data.closest_point(lat)
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
      (@min_latitude..@max_latitude).step(@step) do |lat|
        data[lat] = RangeArray.new(@min_longitude, @max_longitude, @step)
      end
      return data
    end
end
