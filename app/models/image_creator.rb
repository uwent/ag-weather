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

  def self.create_image(data:, title:, file:, subdir: "", scale: nil)
    raise StandardError.new("No data") if data.empty?

    scale ||= [nil, nil]
    # get params from data
    lats = data.keys.map { |lat, lng| lat }.uniq
    lngs = data.keys.map { |lat, lng| lng }.uniq
    extents = [lngs.min, lngs.max, lats.min, lats.max]
    data_min = data.values.min.round(3)
    data_max = data.values.max.round(3)
    auto_min, auto_max = get_min_max(data_min, data_max)
    min = scale.min || auto_min
    max = scale.max || auto_max
    max += 1 if min == max

    # echo params
    Rails.logger.info "#{name} :: Creating image ==> #{file}"
    Rails.logger.debug "#{name} :: Gunplot data range: #{data_min} -> #{data_max} = #{data_max - data_min} (#{(data_max - data_min) / 10.0}/tick)"
    Rails.logger.debug "#{name} :: Gunplot auto range: #{auto_min} -> #{auto_max} = #{auto_max - auto_min} (#{(auto_max - auto_min) / 10.0}/tick)"
    Rails.logger.debug "#{name} :: Gunplot display range: #{min} -> #{max} = #{max - min} (#{(max - min) / 10.0}/tick)"

    # generate image
    datafile_name = create_data_file(data)
    gnuplot_image = run_gnuplot(datafile_name:, title:, min:, max:, extents:)
    file = run_composite(gnuplot_image:, file:, subdir:)
    Rails.logger.debug "#{name} :: Created image #{file}"
    file
  rescue => e
    Rails.logger.error "#{name} :: Failed to create image '#{file}': #{e.message}"
    nil
  end

  # accepts a hash grid not a land grid
  def self.create_data_file(grid)
    data_filename = temp_filename("dat")
    latitudes = grid.keys.map { |lat, _| lat }.uniq
    last_lat = latitudes.min
    File.open(data_filename, "w") do |file|
      grid.each do |key, value|
        lat, lng = key
        # blank line for gnuplot when latitude changes
        file.puts unless lat == last_lat
        file.puts "#{lat} #{lng} #{value.round(3)}" unless value.nil?
        last_lat = lat
      end
    end
    data_filename
  end

  def self.run_gnuplot(datafile_name:, title:, min:, max:, extents:)
    temp_image = temp_filename("png")

    gnuplot_cmd = "gnuplot -e \"plottitle='#{title}'; min_val=#{min}; max_val=#{max}; x_min=#{extents[0]}; x_max=#{extents[1]}; y_min=#{extents[2]}; y_max=#{extents[3]}; outfile='#{temp_image}'; infile='#{datafile_name}';\" lib/color_contour.gp"
    Rails.logger.debug "ImageCreator >> gnuplot cmd: #{gnuplot_cmd}"

    success = system(gnuplot_cmd)
    raise StandardError.new("Gnuplot execution failed for cmd: #{gnuplot_cmd}") unless success
    FileUtils.rm_f(datafile_name)
    temp_image
  end

  def self.run_composite(gnuplot_image:, file:, subdir: "")
    image_dir = File.join(file_dir, subdir)
    FileUtils.mkdir_p(image_dir)
    out_file = File.join(image_dir, file)
    overlay_image = file.include?("-wi.png") ? "lib/wi_overlay.png" : "lib/map_overlay.png"
    image_cmd = "composite '#{overlay_image}' '#{gnuplot_image}' '#{out_file}'"
    Rails.logger.debug "ImageCreator >> imagemagick cmd: #{image_cmd}"

    success = system(image_cmd)
    raise StandardError.new "ImageMagick execution failed for cmd: #{image_cmd}" unless success
    FileUtils.rm_f(gnuplot_image)
    file
  end
end
