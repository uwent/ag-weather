module WiMn

  def self.latitudes
    42..50
  end

  def self.longitudes
    86..98
  end

  def self.step
    0.1
  end

  def self.inside?(lat, long)
    (latitudes === lat) && (longitudes === long)
  end

  def self.each_point
    latitudes.step(step).each do |lat|
      longitudes.step(step).each do |long|
        yield(lat, long)
      end
    end
  end

  def self.num_points
    latitudes.step(step).count * longitudes.step(step).count
  end


end