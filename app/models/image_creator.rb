class ImageCreator
  IMAGE_STEP = 0.1

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
    range = max - min
    return (max + 0.005).round(2) if range <= 1
    return (max + 0.05).round(1) if range <= 10
    max.ceil
  end

  def self.min_value_for_gnuplot(min, max)
    return 0 if min.nil?
    range = max - min
    return (min - 0.005).round(2) if range <= 1
    return (min - 0.05).round(1) if range <= 10
    min.floor
  end

  def self.create_image(data_grid, title, image_name, subdir: "", min_value: nil, max_value: nil)
    grid_min = min_value_for_gnuplot(data_grid.min, data_grid.max)
    grid_max = max_value_for_gnuplot(data_grid.min, data_grid.max)
    min = min_value || grid_min
    max = max_value || grid_max
    Rails.logger.debug "ImageCreator :: Gunplot data range: #{grid_min} -> #{grid_max} = #{grid_max - grid_min} (#{(grid_max - grid_min) / 10.0}/tick)"
    Rails.logger.debug "ImageCreator :: Gunplot display range: #{min} -> #{max} = #{max - min} (#{(max - min) / 10.0}/tick)"
    datafile_name = create_data_file(data_grid)
    image_name = generate_image_file(datafile_name, image_name, subdir, title, min, max)
    File.delete(datafile_name)
    image_name
  end

  def self.create_data_file(data_grid)
    data_filename = temp_filename("dat")
    last_lat = data_grid.latitudes.min
    File.open(data_filename, "w") do |file|
      data_grid.each_point do |lat, long|
        # blank line for gnuplot when latitude changes
        file.puts unless lat == last_lat
        file.puts "#{lat} #{long} #{data_grid[lat, long].round(2)}" unless data_grid[lat, long].nil?
        last_lat = lat
      end
    end
    data_filename
  end

  def self.generate_image_file(datafile_name, image_name, subdir, title, min_value, max_value)
    temp_image = temp_filename("png")
    image_dir = File.join(file_dir, subdir)
    FileUtils.mkdir_p(image_dir)
    Rails.logger.debug "ImageCreator :: Placing image in #{image_dir}"
    image_path = File.join(image_dir, image_name)

    # Gnuplot
    gnuplot_cmd = "gnuplot -e \"plottitle='#{title}'; min_val=#{min_value}; max_val=#{max_value}; outfile='#{temp_image}'; infile='#{datafile_name}';\" lib/color_contour.gp"
    Rails.logger.debug ">> gnuplot cmd: #{gnuplot_cmd}"
    `#{gnuplot_cmd}`
    raise StandardError.new("Gnuplot execution failed") unless $?.success?

    # Image Magick
    image_cmd = "composite lib/map_overlay_branded.png '#{temp_image}' '#{image_path}'"
    Rails.logger.debug ">> imagemagick cmd: #{image_cmd}"
    `#{image_cmd}`
    raise StandardError.new("ImageMagick execution failed") unless $?.success?

    Rails.logger.debug "ImageCreator :: Created image #{image_path}"
    File.delete(temp_image)
    image_name
  rescue => e
    Rails.logger.error "ImageCreator :: Failed to create image: #{e.message}"
    "no_data.png"
  end

end
