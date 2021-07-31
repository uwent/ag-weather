class WiMnGrid < LandGrid

  # Wisconsin and Minnesota for evapo/insol maps

  def extents
    {
      min_lat: 42,
      max_lat: 50,
      min_long: 86,
      max_long: 98,
      step: 0.1
    }
  end

end
