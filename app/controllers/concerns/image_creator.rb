module ImageCreator 
  IMAGE_STEP = 0.2
  GNUPLOT = "/usr/local/bin/gnuplot"
  IMAGEMAGICK_COMP = "/usr/bin/composite"

  def self.create_image(data_grid, title, final_name)
    datafile_name = create_data_file(data_grid)
    image_filename = generate_image_file(datafile_name, final_name, 14, title)

#     File.delete(datafile_name)

    return image_filename
  end

  def self.create_data_file(data_grid)
    data_filename = temp_filename('dat')
    
    last_lat = WiMn::S_LAT
    File.open(data_filename, 'w') do |file| 
      WiMn.each_point(IMAGE_STEP) do |lat, long| 
        # blank line for gnuplot when latitude changes
        file.puts unless lat == last_lat 
        file.puts "#{lat} #{long} #{data_grid[lat,long].round(2)}"
        last_lat = lat
      end
    end

    data_filename
  end

  def self.generate_image_file(datafile_name, image_name, max_value, title)
    temp_image = temp_filename('png')
    %x(#{GNUPLOT} -e "plottitle='#{title}'" -e "max_v=#{max_value}" -e "outfile='#{temp_image}'" -e "infile='#{datafile_name}'" lib/color_contour.gp)
    
    %x(#{IMAGEMAGICK_COMP} -colors 64 wi_mn_trans.png #{temp_image} #{image_name})
    # File.delete(temp_image)
    return image_name
  end

  def self.temp_filename(suffix)
    File.join(Rails.configuration.x.image.temp_directory,
              "#{random_string(8)}_#{DateTime.current.to_s(:number)}.#{suffix}")
  end

  private
    def self.random_string(length)
      (0...length).map { (65 + rand(26)).chr }.join
    end
end
