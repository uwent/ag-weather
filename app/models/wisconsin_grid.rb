class WisconsinGrid < LandGrid

  # Just Wisconsin

  def extents
    {
      min_lat: 42,
      max_lat: 47.1,
      min_long: 86.8,
      max_long: 93.1,
      step: 0.1
    }
  end

end
