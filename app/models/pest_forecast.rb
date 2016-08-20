class PestForecast < ActiveRecord::Base

  def compute_potato_blight_dsv(weather)
    temp = weather.avg_temperature
    hours = weather.hours_rh_over_85

    if temp.in? (7.22 ... 12.222)
      return 1 if hours.in? (16 .. 18)
      return 2 if hours.in? (19 .. 21)
      return 3 if hours >= 22
    elsif temp.in? (12.222 ... 15.556)
      return 1 if hours.in? (13 .. 15)
      return 2 if hours.in? (16 .. 18)
      return 3 if hours.in? (19 .. 21)
      return 4 if hours >= 22
    elsif temp.in? (15.556 .. 26.667)
      return 1 if hours.in? (10 .. 12)
      return 2 if hours.in? (13 .. 15)
      return 3 if hours.in? (16 .. 18)
      return 4 if hours.in? (19 .. 21)
    end
    return 0
  end
end
