class Reading
  attr_accessor :latitude, :longitude, :value
  R = 6371 # Radius of Earth (average)

  def initialize(lat, lng, val)
    @latitude = lat
    @longitude = lng
    @value = val
  end

  def to_s
    "(#{@latitude}, #{@longitude}): #{@value}"
  end

  # This is the simplest way to compute small distances called
  # Equirectangular Approximation.
  # Reference: www.movable-type.co.uk/scripts/latlong.html
  #            (The more complex formula are there as well)
  def distance(other_lat, other_lng)
    x = (to_radians(@longitude) - to_radians(other_lng)) * Math.cos((to_radians(@latitude) + to_radians(other_lat)) / 2)
    y = (to_radians(@latitude) - to_radians(other_lat))
    Math.sqrt(x * x + y * y) * R
  end

  private

  def to_radians(degrees)
    degrees * Math::PI / 180
  end
end
