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

  def self.wi_grid
    new(WiExtent.min_lat, WiExtent.max_lat, WiExtent.min_long, WiExtent.max_long, WiExtent.step)
  end

  def initialize(
    min_lat = LandExtent.min_lat,
    max_lat = LandExtent.max_lat,
    min_long = LandExtent.min_long,
    max_long = LandExtent.max_long,
    step = LandExtent.step,
    default: nil
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
    @data = create_grid(default)
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
    min.nil? && max.nil?
  end

  def num_latitudes
    latitudes.step(@step).count
  end

  def num_longitudes
    longitudes.step(@step).count
  end

  def num_points
    num_latitudes * num_longitudes
  end

  def size
    num_points
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

  def create_grid(default)
    data = RangeArray.new(@min_latitude, @max_latitude, @step)
    (@min_latitude..@max_latitude).step(@step) do |lat|
      data[lat] = RangeArray.new(@min_longitude, @max_longitude, @step, default: default)
    end
    data
  end
end
