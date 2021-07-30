module ImageCreator
  IMAGE_STEP = 0.2
  # GNUPLOT = "/usr/local/bin/gnuplot"
  GNUPLOT = "gnuplot"
  # IMAGEMAGICK_COMP = "/usr/bin/composite"
  IMAGEMAGICK_COMP = "composite"

  def self.url_path
    Rails.configuration.x.image.url_path
  end

  def self.create_image(data_grid, title, file_base_name)
    datafile_name = create_data_file(data_grid)
    image_filename = generate_image_file(
      datafile_name,
      file_base_name,
      max_value_for_gnuplot(data_grid.max),
      title)
    File.delete(datafile_name)
    return image_filename
  end

  def self.create_data_file(data_grid)
    data_filename = temp_filename('dat')

    last_lat = WiMn::S_LAT
    File.open(data_filename, 'w') do |file|
      WiMn.each_point(IMAGE_STEP) do |lat, long|
        # blank line for gnuplot when latitude changes
        file.puts unless lat == last_lat
        file.puts "#{lat} #{long} #{data_grid[lat,long].round(2)}" unless data_grid[lat, long].nil?
        last_lat = lat
      end
    end

    data_filename
  end

  def self.generate_image_file(datafile_name, image_name, max_value, title)
    temp_image = temp_filename('png')
    image_fullpath = File.join(
      Rails.configuration.x.image.file_dir,
      image_name)

    gnuplot_cmd = "(#{GNUPLOT} -e \"plottitle='#{title}'\" -e \"max_v=#{max_value}\" -e \"outfile='#{temp_image}'\" -e \"infile='#{datafile_name}'\" lib/color_contour.gp)"
    Rails.logger.debug("GNUPLOT CMD: #{gnuplot_cmd}")
    %x(#{gnuplot_cmd})

    image_cmd = "#{IMAGEMAGICK_COMP} -colors 64 wi_mn_trans.png #{temp_image} #{image_fullpath}"
    Rails.logger.debug("IMAGEMAGICK CMD: #{image_cmd}")
    %x(#{image_cmd})

    File.delete(temp_image)
    return image_name
  end

  def self.temp_filename(suffix)
    File.join(
      Rails.configuration.x.image.temp_directory,
      "#{random_string(8)}_#{DateTime.current.to_s(:number)}.#{suffix}")
  end

  def self.max_value_for_gnuplot(val)
    if val.nil?
      0
    elsif val < 0.1
      (val + 0.005).round(2)
    elsif val < 1
      (val + 0.05).round(1)
    else
      val.ceil
    end
  end

  private
    def self.random_string(length)
      (0...length).map { (65 + rand(26)).chr }.join
    end
end
