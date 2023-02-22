module ImageMethods
  def image_subdir
  end

  def image_path(filename)
    File.join(ImageCreator.file_dir, image_subdir, filename)
  end

  def image_url(filename)
    File.join(ImageCreator.url_path, image_subdir, filename)
  end

  def default_units(col)
    valid_units[0]
  end

  def default_scale(units)
  end

  def image_name_prefix(*args)
    name.downcase
  end

  def image_title(*args)
    name
  end

  def image_name(
    date: nil,
    start_date: nil,
    end_date: nil,
    col: nil,
    units: nil,
    extent: nil,
    scale: nil,
    stat: nil
  )

    end_date ||= date
    raise ArgumentError.new log_prefix + "Must provide either 'date' or 'end_date'" unless end_date

    file = image_name_prefix(col:, units:, stat:)
    file += "-#{units.downcase}" if units
    file += "-#{start_date.to_date.to_formatted_s(:number)}" if start_date
    file += "-#{end_date.to_date.to_formatted_s(:number)}"
    file += "-range-#{scale.min}-#{scale.max}" if scale && scale != default_scale(units)
    file += "-#{extent}" if extent == "wi"
    file + ".png"
  end

  def create_image(
    date:,
    col: default_col,
    units: nil,
    extent: nil,
    scale: nil
  )

    date = date.to_date
    raise ArgumentError.new log_prefix + "Must name a column to image" unless col
    units ||= default_units(col)
    scale ||= default_scale(units)
    land_extent = (extent == "wi") ? WiExtent : LandExtent
    data = hash_grid(date:, extent: land_extent, units:, col:)

    # call image creator
    title = image_title(date:, col:, units:)
    file = image_name(date:, col:, units:, extent:, scale:)
    ImageCreator.create_image(data, title, file, subdir: image_subdir, scale:)
  end

  def create_cumulative_image(
    start_date: latest_date.beginning_of_year,
    end_date: latest_date,
    col: default_col,
    units: nil,
    stat: default_stat,
    extent: nil,
    scale: nil
  )

    raise ArgumentError.new log_prefix + "Must name a column to image" unless col
    units ||= default_units(col)

    # create data grid
    land_extent = (extent == "wi") ? WiExtent : LandExtent
    data = cumulative_hash_grid(start_date:, end_date:, extent: land_extent, units:, col:, stat:)

    # get actual date range
    point = where(date: start_date..end_date, latitude: land_extent.min_lat, longitude: land_extent.min_long)
    start_date = point.minimum(:date)
    end_date = point.maximum(:date)

    # call image creator
    title = image_title(start_date:, end_date:, col:, units:, stat:)
    file = image_name(start_date:, end_date:, col:, units:, extent:, scale:, stat:)
    ImageCreator.create_image(data, title, file, subdir: image_subdir, scale:)
  end
end
