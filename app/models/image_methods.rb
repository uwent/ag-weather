module ImageMethods
  def image_subdir
  end

  def image_path(filename)
    File.join(ImageCreator.file_dir, image_subdir, filename)
  end

  def image_url(filename)
    File.join(ImageCreator.url_path, image_subdir, filename)
  end

  def default_units(col = nil)
    valid_units[0]
  end

  def default_scale(**args)
  end

  # daily unless "cumulative"
  def default_image_type
  end

  def image_name_prefix(**args)
    title = ""
    title += "#{args[:stat]}-" if args[:stat] && args[:stat] != default_stat
    title + name.downcase
  end

  def image_title(**args)
    name
  end

  def image_title_date(end_date:, start_date: nil)
    start_date = start_date&.to_date
    end_date = end_date&.to_date
    fmt1 = "%b %-d, %Y"
    fmt2 = "%b %-d"
    end_date_string = end_date.strftime(fmt1)

    if start_date.nil?
      end_date_string
    else
      fmt = (start_date.year != end_date.year) ? fmt1 : fmt2
      "#{start_date.strftime(fmt)} - #{end_date_string}"
    end
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
    raise ArgumentError.new "Must provide either 'date' or 'end_date'" unless end_date

    file = image_name_prefix(col:, units:, stat:)
    file += "-#{units.downcase}" if units
    file += "-#{start_date.to_date.to_formatted_s(:number)}" if start_date
    file += "-#{end_date.to_date.to_formatted_s(:number)}"
    file += "-range-#{scale.min}-#{scale.max}" if scale && scale != default_scale(col:, units:)
    file += "-#{extent}" if extent == "wi"
    file += ".png"
    ActiveStorage::Filename.new(file).sanitized.squeeze("-")
  end

  def guess_image(**args)
    if args[:date]
      create_image(**args)
    elsif args[:start_date] || args[:end_date]
      create_cumulative_image(**args)
    else
      raise ArgumentError.new "Must provide either 'date' or 'end_date'"
    end
  end

  def create_image(
    date:,
    col: default_col,
    units: nil,
    extent: nil,
    scale: nil,
    **args
  )
    date = date.to_date
    raise ArgumentError.new "Must name a column to image" unless col

    units ||= default_units(col)
    scale ||= default_scale(col:, units:)
    land_extent = (extent == "wi") ? WiExtent : LandExtent
    data = hash_grid(date:, units:, col:, extent: land_extent)

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
    scale: nil,
    **args
  )
    raise ArgumentError.new "Must name a column to image" unless col
    units ||= default_units(col)

    # create data grid
    land_extent = (extent == "wi") ? WiExtent : LandExtent
    data = cumulative_hash_grid(start_date:, end_date:, units:, col:, stat:, extent: land_extent)

    # get actual date range
    point = where(date: start_date..end_date, latitude: land_extent.min_lat, longitude: land_extent.min_long)
    start_date = point.minimum(:date) || start_date
    end_date = point.maximum(:date) || end_date

    # call image creator
    title = image_title(start_date:, end_date:, col:, units:, stat:)
    file = image_name(start_date:, end_date:, col:, units:, extent:, scale:, stat:)
    ImageCreator.create_image(data, title, file, subdir: image_subdir, scale:)
  end
end
