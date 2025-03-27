module GridMethods
  def attr_cols
    [:id, :latitude, :longitude, :date]
  end

  def data_cols
    column_names.map(&:to_sym) - attr_cols
  end

  def default_col
  end

  def default_grid
    LandGrid.new
  end

  def valid_units
    []
  end

  def convert(value:, **args)
    value
  end

  def valid_stats
    [:avg, :min, :max, :sum]
  end

  def default_stat
    :sum
  end

  def all_for_date(date)
    where(date:).order(:latitude, :longitude)
  end

  def lat_range
    [minimum(:latitude), maximum(:latitude)]
  end

  def lng_range
    [minimum(:longitude), maximum(:longitude)]
  end

  def extent
    {latitude: lat_range, longitude: lng_range}
  end

  def grid_summarize(sql = nil)
    group(:latitude, :longitude)
      .order(:latitude, :longitude)
      .select(:latitude, :longitude, sql)
  end

  # collects all records for date and inserts them into a land grid
  def land_grid(date:, grid: default_grid)
    check_grid(grid)

    all_for_date(date).each do |point|
      lat, lng = point.latitude, point.longitude
      next unless grid.inside?(lat, lng)
      grid[lat, lng] = point
    end
    grid
  end

  # creates a hash keyed by [lat, lng] with a column value at each key
  def hash_grid(
    date:,
    col: default_col,
    extent: LandExtent,
    units: valid_units[0]
  )
    check_col(col)
    check_extent(extent)

    grid = {}
    where(date:).each do |point|
      lat, lng = point.latitude, point.longitude
      next unless extent.inside?(lat, lng)
      value = point.send(col)
      grid[[lat, lng]] = units ? convert(value:, col:, units:) : value
    end
    grid
  end

  # creates a hash keyed by [lat, lng] with a summarized value at each key
  def cumulative_hash_grid(
    col: default_col,
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    extent: LandExtent,
    units: nil,
    stat: default_stat
  )
    check_col(col)
    check_extent(extent)
    check_stat(stat)

    grid = {}
    data = where(date: start_date..end_date).grid_summarize("#{stat}(#{col}) as value")
    data.each do |point|
      lat, lng = point.latitude, point.longitude
      next unless extent.inside?(lat, lng)
      value = point.value
      grid[[lat, lng]] = units ? convert(value:, col:, units:) : value
    end
    grid
  end

  def check_col(col)
    if !data_cols.include?(col) && !data_cols.include?(col&.to_sym)
      raise ArgumentError.new "'#{col.inspect}' is not a valid data column for #{name}. Must be one of #{data_cols.join(", ")}"
    end
  end

  def check_grid(grid)
    raise ArgumentError.new "Grid is of incorrect type, must be LandGrid" unless grid.is_a? LandGrid
  end

  def check_extent(extent)
    raise ArgumentError.new "Extent is of incorrect type, must be LandExtent" unless extent.is_a?(Class) && extent.new.is_a?(LandExtent)
  end

  def check_units(unit)
    return if valid_units.empty? || unit.nil?
    raise ArgumentError.new "Unit has invalid value: #{unit.inspect}. Must be one of #{valid_units.join(", ")}" unless valid_units.include? unit
  end

  def check_stat(stat)
    raise ArgumentError.new "Invalid aggregation function: #{stat.inspect}. Must be one of #{valid_stats.join(", ")}" unless valid_stats.include? stat
  end
end
