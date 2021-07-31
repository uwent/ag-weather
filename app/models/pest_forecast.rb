class PestForecast < ApplicationRecord

  NO_MAX = 150

  def self.for_lat_long_date_range(lat, long, start_date, end_date)
    where(latitude: lat, longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date)
      .order(date: :desc)
  end

  # degree days in F
  def self.new_from_weather(weather)
    PestForecast.new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_late_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      dd_39p2_86: weather.degree_days('sine', 39.2, 86),    # 4 / 30 C
      dd_41_86: weather.degree_days('sine', 41, 86),        # 5 / 30 C
      dd_41_88: weather.degree_days('sine', 41, 88),        # 5 / 31 C
      dd_41_none: weather.degree_days('sine', 41, NO_MAX),  # 5 / none C
      dd_42p8_86: weather.degree_days('sine', 42.8, 86),    # 6 / 30 C
      dd_45_none: weather.degree_days('sine', 45, NO_MAX),  # 7.2 / none C
      dd_45_86: weather.degree_days('sine', 45, 86),        # 7.2 / 30 C
      dd_48_none: weather.degree_days('sine', 48, NO_MAX),  # 9 / none C
      dd_50_86: weather.degree_days('sine', 50, 86),        # 10 / 30 C
      dd_50_88: weather.degree_days('sine', 50, 88),        # 10 / 31.1 C
      dd_50_90: weather.degree_days('sine', 50, 90),        # 10 / 32.2 C
      dd_50_none: weather.degree_days('sine', 50, NO_MAX),  # 10 / none C
      dd_52_none: weather.degree_days('sine', 52, NO_MAX),  # 11.1 / none C
      dd_54_92: weather.degree_days('sine', 54, 92),        # 12.2 / 33.3 C
      dd_55_92: weather.degree_days('sine', 55, 92)         # 12.8 / 33.3 C
    )
  end

  def self.calculate_p_day(min, max)
    a = 5 * p_val(min)
    b = 8 * p_val((2 * min / 3) + (max / 3))
    c = 8 * p_val((2 * max / 3) + (min / 3))
    d = 3 * p_val(min)
    return (a + b + c + d) / 24.0
  end

  def self.p_val(temp)
    # temp in C
    return 0 if temp < 7
    return 10 * (1 - ((temp - 21)**2 / 196)) if temp.between?(7, 21) # 196 = (21-7)^2
    return 10 * (1 - ((temp - 21)**2 / 81)) if temp.between?(21, 30) # 81 = (30-21)^2
    return 0
  end

  # temps in celcius
  def self.compute_potato_p_days(weather)
    min = weather.min_temperature || 0
    max = weather.max_temperature || 0
    return calculate_p_day(min, max)
  end

  # temp in celcius
  def self.compute_late_blight_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    return late_blight_logic(temp, hours)
  end

  def self.late_blight_logic(temp, hours)
    # temp in C
    if temp.in? 7.22...12.22
      return 0 if hours < 16
      return 1 if hours.in? 16..18
      return 2 if hours.in? 19..21
      return 3 if hours > 21
    elsif temp.in? 12.22...15.55
      return 0 if hours < 13
      return 1 if hours.in? 13..15
      return 2 if hours.in? 16..18
      return 3 if hours.in? 19..21
      return 4 if hours > 21
    elsif temp > 15.55
      return 0 if hours < 10
      return 1 if hours.in? 10..12
      return 2 if hours.in? 13..15
      return 3 if hours.in? 16..18
      return 4 if hours > 18
    end
    return 0
  end

  def self.compute_carrot_foliar_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    return carrot_foliar_logic(temp, hours)
  end

  def self.carrot_foliar_logic(temp, hours)
    # temp in C
    if temp.in? 13...18
      return 0 if hours < 7
      return 1 if hours.in? 7..15
      return 2 if hours.in? 16..20
      return 3 if hours > 20
    elsif temp.in? 18...21
      return 0 if hours < 4
      return 1 if hours.in? 4..8
      return 2 if hours.in? 9..15
      return 3 if hours.in? 16..22
      return 4 if hours > 22
    elsif temp.in? 21...26
      return 0 if hours < 3
      return 1 if hours.in? 3..5
      return 2 if hours.in? 6..12
      return 3 if hours.in? 13..20
      return 4 if hours > 20
    elsif temp > 26
      return 0 if hours < 4
      return 1 if hours.in? 4..8
      return 2 if hours.in? 9..15
      return 3 if hours.in? 16..22
      return 4 if hours > 22
    end
    return 0
  end

  def self.compute_cercospora_div(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp_c = weather.avg_temp_rh_over_90 || weather.avg_temperature
    temp = (temp_c * 9/5) + 32.0

    return cercospora_logic(temp, hours)    
  end

  def self.cercospora_logic(temp, hours)
    # temp in F
    return 0 if temp < 60
    if temp < 61
      return 0 if hours <= 21
      return 1
    elsif temp < 62
      return 0 if hours <= 19
      return 1 if hours <= 22
      return 2
    elsif temp < 63
      return 0 if hours <= 16
      return 1 if hours <= 19
      return 2 if hours <= 21
      return 3
    elsif temp < 64
      return 0 if hours <= 13
      return 1 if hours <= 15
      return 2 if hours <= 18
      return 3 if hours <= 20
      return 4 if hours <= 23
      return 5
    elsif temp < 65
      return 0 if hours <= 6
      return 1 if hours <= 8
      return 2 if hours <= 12
      return 3 if hours <= 18
      return 4 if hours <= 21
      return 5
    elsif temp < 71
      return 0 if hours <= 3
      return 1 if hours <= 6
      return 2 if hours <= 10
      return 3 if hours <= 14
      return 4 if hours <= 18
      return 5 if hours <= 21
      return 6
    elsif temp < 72
      return 0 if hours <= 2
      return 1 if hours <= 6
      return 2 if hours <= 9
      return 3 if hours <= 13
      return 4 if hours <= 17
      return 5 if hours <= 20
      return 6
    elsif temp < 73
      return 0 if hours <= 1
      return 1 if hours <= 6
      return 2 if hours <= 9
      return 3 if hours <= 12
      return 4 if hours <= 16
      return 5 if hours <= 19
      return 6
    elsif temp < 76
      return 1 if hours <= 5
      return 2 if hours <= 9
      return 3 if hours <= 11
      return 4 if hours <= 16
      return 5 if hours <= 18
      return 6 if hours <= 23
      return 7
    elsif temp < 77
      return 1 if hours <= 5
      return 2 if hours <= 8
      return 3 if hours <= 12
      return 4 if hours <= 15
      return 5 if hours <= 18
      return 6 if hours <= 22
      return 7
    elsif temp < 78
      return 1 if hours <= 5
      return 2 if hours <= 8
      return 3 if hours <= 11
      return 4 if hours <= 14
      return 5 if hours <= 17
      return 6 if hours <= 20
      return 7
    elsif temp < 79
      return 1 if hours <= 4
      return 2 if hours <= 7
      return 3 if hours <= 9
      return 4 if hours <= 12
      return 5 if hours <= 14
      return 6 if hours <= 17
      return 7
    elsif temp < 80
      return 1 if hours <= 3
      return 2 if hours <= 6
      return 3 if hours <= 8
      return 4 if hours <= 10
      return 5 if hours <= 12
      return 6 if hours <= 15
      return 7
    elsif temp < 81
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 6
      return 4 if hours <= 7
      return 5 if hours <= 9
      return 6 if hours <= 11
      return 7
    elsif temp < 82
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 5
      return 4 if hours <= 7
      return 5 if hours <= 8
      return 6 if hours <= 10
      return 7
    else
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 5
      return 4 if hours <= 7
      return 5 if hours <= 8
      return 6 if hours <= 9
      return 7
    end
  end

end
