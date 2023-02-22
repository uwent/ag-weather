module GridMethods
  def default_col
  end

  def default_grid
    LandGrid.new
  end

  def valid_units
    []
  end

  def convert(value:, col: nil, units: nil)
    value
  end

  def valid_stats
    [:avg, :count, :min, :max, :sum]
  end

  def default_stat
    :sum
  end

  def all_for_date(date)
    where(date:).order(:latitude, :longitude)
  end

  def extent
    {
      latitude: [minimum(:latitude).to_s, maximum(:latitude).to_s],
      longitude: [minimum(:longitude).to_s, maximum(:longitude).to_s]
    }
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
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = point
    end
    grid
  end

  # creates a hash keyed by [lat, long] with a column value at each key
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
      lat, long = point.latitude, point.longitude
      next unless extent.inside?(lat, long)
      value = point.send(col)
      grid[[lat, long]] = units ? convert(value:, col:, units:) : value
    end
    grid
  end

  # creates a hash keyed by [lat, long] with a summarized value at each key
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
      lat, long = point.latitude, point.longitude
      next unless extent.inside?(lat, long)
      value = point.value
      grid[[lat, long]] = units ? convert(value:, col:, units:) : value
    end
    grid
  end

  def check_col(col)
    col = col.to_s
    raise ArgumentError.new(log_prefix(1) + "'#{col.inspect} is not a valid data column for #{name}. Must be one of #{column_names.join(", ")}") unless column_names.include? col
  end

  def check_grid(grid)
    raise ArgumentError.new(log_prefix(1) + "Grid is of incorrect type: #{grid.name}") unless grid.is_a? LandGrid
  end

  def check_extent(extent)
    raise ArgumentError.new(log_prefix(1) + "Extent is of incorrect type: #{extent.name}") unless extent.new.is_a? LandExtent
  end

  def check_units(unit)
    return if valid_units.empty? || unit.nil?
    raise ArgumentError.new(log_prefix(1) + "Unit has invalid value: #{unit.inspect}. Must be one of #{valid_units.join(", ")}") unless valid_units.include? unit
  end

  def check_stat(stat)
    raise ArgumentError.new log_prefix(1) + "Invalid aggregation function: #{stat.inspect}. Must be one of #{valid_stats.join(", ")}" unless valid_stats.include? stat
  end
end
