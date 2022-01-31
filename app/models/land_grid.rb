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

  def self.wi_mn_grid
    new(WiMn.min_lat, WiMn.max_lat, WiMn.min_long, WiMn.max_long, WiMn.step)
  end

  def self.wisconsin_grid
    new(Wisconsin.min_lat, Wisconsin.max_lat, Wisconsin.min_long, Wisconsin.max_long, Wisconsin.step)
  end

  def initialize(
    min_lat = LandExtent.min_lat,
    max_lat = LandExtent.max_lat,
    min_long = LandExtent.min_long,
    max_long = LandExtent.max_long,
    step = LandExtent.step
  )

    raise TypeError, "minimum latitude must be less than maximum latitude" if min_lat >= max_lat
    raise TypeError, "minimum longitude must be less than maximum longitude" if min_long >= max_long
    raise TypeError, "step must be greater than 0" if step <= 0
    raise TypeError, "step must be less than latitude difference and longitude difference" if step > max_lat - min_lat || step > max_long - min_long

    @min_latitude = min_lat
    @max_latitude = max_lat
    @min_longitude = min_long
    @max_longitude = max_long
    @step = step
    @data = create_grid
  end

  def latitudes
    @min_latitude..@max_latitude
  end

  def longitudes
    @min_longitude..@max_longitude
  end

  # xmin, xmax, ymin, ymax
  def extents
    [@min_longitude, @max_longitude, @min_latitude, @max_latitude]
  end

  def inside?(lat, long)
    (latitudes === lat) && (longitudes === long)
  end

  def empty?
    self.min.nil? && self.max.nil?
  end

  def each_point
    latitudes.step(@step).each do |lat|
      longitudes.step(@step).each do |long|
        yield(lat, long)
      end
    end
  end

  def closest_point(lat, long)
    lat = @data.closest_point(lat)
    [lat, @data[lat].closest_point(long)]
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
    data
  end
end
