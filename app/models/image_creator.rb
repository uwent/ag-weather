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
    FileUtils.mkdir_p(temp_dir)
    File.join(temp_dir, "#{SecureRandom.urlsafe_base64(8)}.#{suffix}")
  end

  def self.get_min_max(min, max)
    min ||= 0
    max ||= min
    # puts "#{min}, #{max} (#{tick}/tick) ==>"
    d = if max - min <= 1
      2
    elsif max - min <= 10
      1
    else
      0
    end
    min = min.floor(d - 1)
    tick = ((max - min) / 10.0).ceil(d)
    max = (min + tick * 10.0).ceil(d - 1)
    # puts "#{min}, #{max} (#{tick}/tick)"
    [min, max]
  end

  def self.create_image(grid, title, image_name, subdir: "", min_value: nil, max_value: nil)
    return if grid.empty?

    # get params from data
    data_min = grid.min.round(3)
    data_max = grid.max.round(3)
    auto_min, auto_max = get_min_max(grid.min, grid.max)
    min = min_value || auto_min
    max = max_value || auto_max
    max += 1 if min == max

    # echo params
    Rails.logger.debug "ImageCreator :: Gunplot data range: #{data_min} -> #{data_max} = #{data_max - data_min} (#{(data_max - data_min) / 10.0}/tick)"
    Rails.logger.debug "ImageCreator :: Gunplot auto range: #{auto_min} -> #{auto_max} = #{auto_max - auto_min} (#{(auto_max - auto_min) / 10.0}/tick)"
    Rails.logger.debug "ImageCreator :: Gunplot display range: #{min} -> #{max} = #{max - min} (#{(max - min) / 10.0}/tick)"

    # generate images
    begin
      datafile_name = create_data_file(grid)
      gnuplot_image = run_gnuplot(datafile_name, title, min, max, grid.extents)
      image_name = run_composite(gnuplot_image, image_name, subdir)
      Rails.logger.debug "ImageCreator :: Created image #{image_name}"
      image_name
    rescue => e
      Rails.logger.error "ImageCreator :: Failed to create image '#{image_name}': #{e.message}"
      nil
    end
    # image_name = generate_image_file(datafile_name, image_name, subdir, title, min, max, grid.extents)
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

  def self.run_gnuplot(datafile_name, title, min, max, extents)
    temp_image = temp_filename("png")

    gnuplot_cmd = "gnuplot -e \"plottitle='#{title}'; min_val=#{min}; max_val=#{max}; x_min=#{extents[0]}; x_max=#{extents[1]}; y_min=#{extents[2]}; y_max=#{extents[3]}; outfile='#{temp_image}'; infile='#{datafile_name}';\" lib/color_contour.gp"
    Rails.logger.debug "ImageCreator >> gnuplot cmd: #{gnuplot_cmd}"
    `#{gnuplot_cmd}`

    FileUtils.rm_f(datafile_name)
    raise StandardError.new("Gnuplot execution failed with status: #{$?.exitstatus}") if $?.exitstatus != 0
    temp_image
  end

  def self.run_composite(gnuplot_image, image_name, subdir)
    image_dir = File.join(file_dir, subdir)
    FileUtils.mkdir_p(image_dir)
    out_file = File.join(image_dir, image_name)
    overlay_image = image_name.include?("-wi.png") ? "lib/wi_overlay.png" : "lib/map_overlay.png"

    image_cmd = "composite '#{overlay_image}' '#{gnuplot_image}' '#{out_file}'"
    Rails.logger.debug "ImageCreator >> imagemagick cmd: #{image_cmd}"
    `#{image_cmd}`

    FileUtils.rm_f(gnuplot_image)
    raise StandardError.new("ImageMagick execution failed with status: #{$?.exitstatus}") if $?.exitstatus != 0
    image_name
  end
end
