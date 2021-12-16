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

  def self.min_max(min, max)
    min ||= 0
    max ||= min
    range = max - min
    tick = range / 10.0
    # puts "#{min}, #{max} (#{tick}/tick) ==>"
    d = if range <= 1
      2
    elsif range <= 10
      1
    else
      0
    end
    tick = tick.ceil(d)
    min = min.floor(d - 1)
    max = (min + tick * 10.0).ceil(d - 1)
    # puts "#{min}, #{max} (#{tick}/tick)"
    [min, max]
  end

  def self.create_image(grid, title, image_name, subdir: "", min_value: nil, max_value: nil)
    auto_min, auto_max = min_max(grid.min, grid.max)
    min = min_value || auto_min
    max = max_value || auto_max
    max += 1 if min == max
    # Rails.logger.debug "ImageCreator :: Gunplot data range: #{grid.min} -> #{grid.max} = #{grid.min - grid.min} (#{(grid.max - grid.min) / 10.0}/tick)"
    Rails.logger.debug "ImageCreator :: Gunplot auto range: #{auto_min} -> #{auto_max} = #{auto_max - auto_min} (#{(auto_max - auto_min) / 10.0}/tick)"
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
