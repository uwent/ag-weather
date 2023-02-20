module GridMethods

  def default_col
  end

  def default_grid
    LandGrid.new
  end

  def valid_units
    []
  end

  def convert(value, units)
    value
  end

  def valid_stats
    [:avg, :count, :min, :max, :sum]
  end

  def default_stat
    :sum
  end

  def land_grid(
    date:,
    col: default_col,
    grid: default_grid,
    units: valid_units[0])

    check_col(col)
    check_grid(grid)
    check_units(units)

    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = convert(point.send(col), units)
    end
    grid
  end

  def cumulative_land_grid(
    col: default_col,
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    grid: default_grid,
    units: valid_units[0],
    stat: default_stat)

    check_col(col)
    check_grid(grid)
    check_units(units)
    check_stat(stat)

    data = where(date: start_date..end_date).grid_summarize("#{stat}(#{col}) as value")
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless grid.inside?(lat, long)
      grid[lat, long] = convert(point.value, units)
    end
    grid
  end

  def hash_grid(
    date:,
    col: default_col,
    extent: LandExtent,
    units: valid_units[0])

    check_col(col)
    check_extent(extent)
    check_units(units)

    grid = {}
    where(date:).each do |point|
      lat, long = point.latitude, point.longitude
      next unless extent.inside?(lat, long)
      grid[[lat, long]] = convert(point.send(col), units)
    end
    grid
  end

  def cumulative_hash_grid(
    col: default_col,
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    extent: LandExtent,
    units: valid_units[0],
    stat: default_stat)

    check_col(col)
    check_extent(extent)
    check_units(units)
    check_stat(stat)

    grid = {}
    data = where(date: start_date..end_date).grid_summarize("#{stat}(#{col}) as value")
    data.each do |point|
      lat, long = point.latitude, point.longitude
      next unless extent.inside?(lat, long)
      grid[[lat, long]] = convert(point.value, units)
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
    return if valid_units.empty?
    raise ArgumentError.new(log_prefix(1) + "Unit has invalid value: #{unit.inspect}. Must be one of #{valid_units.join(", ")}") unless valid_units.include? unit
  end

  def check_stat(stat)
    raise ArgumentError.new log_prefix(1) + "Invalid aggregation function: #{stat.inspect}. Must be one of #{valid_stats.join(", ")}" unless valid_stats.include? stat
  end
end
