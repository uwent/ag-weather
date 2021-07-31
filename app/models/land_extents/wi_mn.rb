class WiMn

  # Wisconsin and Minnesota for evapo/insol maps

  # def self.latitudes
  #   42..50
  # end

  # def self.longitudes
  #   86..98
  # end

  def extents
    {
      min_lat: 38,
      max_lat: 50,
      min_long: 82,
      max_long: 98,
      step: 0.1
    }
  end

end
