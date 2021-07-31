class LandGrid

  def extents
    {
      min_lat: 38,
      max_lat: 50,
      min_long: 82,
      max_long: 98,
      step: 0.1
    }
  end

  # def extents
  #   {
  #     min_lat: 44,
  #     max_lat: 45,
  #     min_long: 85,
  #     max_long: 86,
  #     step: 0.1
  #   }
  # end

  def initialize(e = extents)
    @min_latitude = e[:min_lat]
    @max_latitude = e[:max_lat]
    @min_longitude = e[:min_long]
    @max_longitude = e[:max_long]
    @step = e[:step]
    @data = create_grid
  end

  # def self.seed
  #   @data = create_grid
  # end

  def each(&block)
    @data.each do |row|
      row.each do |value|
        block.call(value)
      end
    end
  end

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
