class ImageCreator

  def self.url_path
    Rails.configuration.x.image.url_path
  end

  def self.file_dir
    Rails.configuration.x.image.file_dir
  end

  def self.temp_dir
    Rails.configuration.x.image.temp_directory
  end

  def self.temp_filename(suffix)
    File.join(temp_dir, "#{SecureRandom.urlsafe_base64(8)}.#{suffix}")
  end

  def self.max_value_for_gnuplot(min, max)
    return 0 if max.nil?
    return 1 if max.zero?
    range = max - min
    return (max + 0.005).round(2) if range <= 1
    return (max + 0.05).round(1) if range <= 10
    max.ceil
  end

  def self.min_value_for_gnuplot(min, max)
    return 0 if min.nil? || min.zero?
    range = max - min
    return (min - 0.005).round(2) if range <= 1
    return (min - 0.05).round(1) if range <= 10
    min.floor
  end

  def self.create_image(grid, title, image_name, subdir: "", min_value: nil, max_value: nil)
    grid_min = min_value_for_gnuplot(grid.min, grid.max)
    grid_max = max_value_for_gnuplot(grid.min, grid.max)
    min = min_value || grid_min
    max = max_value || grid_max
    Rails.logger.debug "ImageCreator :: Gunplot data range: #{grid_min} -> #{grid_max} = #{grid_max - grid_min} (#{(grid_max - grid_min) / 10.0}/tick)"
    Rails.logger.debug "ImageCreator :: Gunplot display range: #{min} -> #{max} = #{max - min} (#{(max - min) / 10.0}/tick)"
    datafile_name = create_data_file(grid)
    image_name = generate_image_file(datafile_name, image_name, subdir, title, min, max, grid.extents)
    File.delete(datafile_name)
    image_name
  end

  def self.create_data_file(grid)
    data_filename = temp_filename("dat")
    last_lat = grid.latitudes.min
    File.open(data_filename, "w") do |file|
      grid.each_point do |lat, long|
        # blank line for gnuplot when latitude changes
        file.puts unless lat == last_lat
        file.puts "#{lat} #{long} #{grid[lat, long].round(2)}" unless grid[lat, long].nil?
        last_lat = lat
      end
    end
    data_filename
  end

  def self.generate_image_file(datafile_name, image_name, subdir, title, min_value, max_value, extents)
    temp_image = temp_filename("png")
    image_dir = File.join(file_dir, subdir)
    FileUtils.mkdir_p(image_dir)
    image_path = File.join(image_dir, image_name)

    overlay_image = "lib/map_overlay.png"
    overlay_image = "lib/wi_overlay.png" if image_name.include? "-wi.png" # TODO this is dumb

    # Gnuplot
    gnuplot_cmd = "gnuplot -e \"plottitle='#{title}'; min_val=#{min_value}; max_val=#{max_value}; x_min=#{extents[0]}; x_max=#{extents[1]}; y_min=#{extents[2]}; y_max=#{extents[3]}; outfile='#{temp_image}'; infile='#{datafile_name}';\" lib/color_contour.gp"
    Rails.logger.debug ">> gnuplot cmd: #{gnuplot_cmd}"
    `#{gnuplot_cmd}`
    raise StandardError.new("ImageCreator :: Gnuplot execution failed!") if $?.exitstatus == 1

    # Image Magick
    image_cmd = "composite '#{overlay_image}' '#{temp_image}' '#{image_path}'"
    Rails.logger.debug ">> imagemagick cmd: #{image_cmd}"
    `#{image_cmd}`

    raise StandardError.new("ImageCreator :: ImageMagick execution failed!") if $?.exitstatus == 1
    Rails.logger.debug "ImageCreator :: Created image #{image_path}"
    File.delete(temp_image)
    image_name
  rescue => e
    Rails.logger.error "ImageCreator :: Failed to create image: #{e.message}"
    "no_data.png"
  end
end
