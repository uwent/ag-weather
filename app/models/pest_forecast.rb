class PestForecast < ApplicationRecord

  NO_MAX = 150

  def self.for_lat_long_date_range(lat, long, start_date, end_date)
    where(latitude: lat)
      .where(longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date)
      .order(date: :desc)
  end

  def self.new_from_weather(weather)
    PestForecast.new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_potato_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      alfalfa_weevil: weather.degree_days('sine', 48, NO_MAX),
      asparagus_beetle: weather.degree_days('sine', 50, 86),
      black_cutworm: weather.degree_days('sine', 50, 86),
      brown_marmorated_stink_bug: weather.degree_days('sine', 54, 92),
      cabbage_looper: weather.degree_days('sine', 50, 90),
      cabbage_maggot: weather.degree_days('sine', 42.8, 86),
      colorado_potato_beetle: weather.degree_days('sine', 52, NO_MAX),
      corn_earworm: weather.degree_days('sine', 55, 92),
      corn_rootworm: weather.degree_days('sine', 52, NO_MAX),
      european_corn_borer: weather.degree_days('sine', 50, 86),
      flea_beetle_mint: weather.degree_days('sine', 41, NO_MAX),
      flea_beetle_crucifer: weather.degree_days('sine', 50, NO_MAX),
      imported_cabbageworm: weather.degree_days('sine', 50, NO_MAX),
      japanese_beetle: weather.degree_days('sine', 50, NO_MAX),
      lygus_bug: weather.degree_days('sine', 52, NO_MAX),
      mint_root_borer: weather.degree_days('sine', 50, NO_MAX),
      onion_maggot: weather.degree_days('sine', 39.2, 86),
      potato_psyllid: weather.degree_days('sine', 40, 86),
      seedcorn_maggot: weather.degree_days('sine', 39.2, 86),
      squash_vine_borer: weather.degree_days('sine', 50, NO_MAX),
      stalk_borer: weather.degree_days('sine', 41, 86),
      variegated_cutworm: weather.degree_days('sine', 41, 88),
      western_bean_cutworm: weather.degree_days('sine', 50, NO_MAX),
      western_flower_thrips: weather.degree_days('sine', 45, NO_MAX))
  end

  def self.calculate_p_day(min, max)
    def self.p(temp)
      return 0 if temp < 7
      return 10 * (1 - ((temp - 21)**2 / 196)) if temp.between?(7, 21) # 196 = (21-7)^2
      return 10 * (1 - ((temp - 21)**2 / 81)) if temp.between?(21, 30) # 81 = (30-21)^2
      return 0
    end
    a = 5 * p(min)
    b = 8 * p((2 * min / 3) + (max / 3))
    c = 8 * p((2 * max / 3) + (min / 3))
    d = 3 * p(min)
    return (a + b + c + d) / 24.0
  end

  # temps in celcius
  def self.compute_potato_p_days(weather)
    min = weather.min_temperature || 0
    max = weather.max_temperature || 0
    return calculate_p_day(min, max)
  end

  # temp in celcius
  def self.compute_potato_blight_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    # temp in celcius
    if temp.in? (7.22 ... 12.22)
      return 1 if hours.in? (16 .. 18)
      return 2 if hours.in? (19 .. 21)
      return 3 if hours >= 22
    elsif temp.in? (12.22 ... 15.55)
      return 1 if hours.in? (13 .. 15)
      return 2 if hours.in? (16 .. 18)
      return 3 if hours.in? (19 .. 21)
      return 4 if hours >= 22
    elsif temp.in? (15.55 ... 26.66)
      return 1 if hours.in? (10 .. 12)
      return 2 if hours.in? (13 .. 15)
      return 3 if hours.in? (16 .. 18)
      return 4 if hours.in? (19 .. 21)
    end

    return 0
  end

  def self.compute_carrot_foliar_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    # temp in celcius
    if temp.in? (13 ... 18)
      return 1 if hours.in? (7 .. 15)
      return 2 if hours.in? (16 .. 20)
      return 3 if hours > 20
    elsif temp.in? (18 ... 21)
      return 1 if hours.in? (4 .. 8)
      return 2 if hours.in? (9 .. 15)
      return 3 if hours.in? (16 .. 22)
      return 4 if hours > 22
    elsif temp.in? (21 ... 26)
      return 1 if hours.in? (3 .. 5)
      return 2 if hours.in? (6 .. 12)
      return 3 if hours.in? (13 .. 20)
      return 4 if hours > 20
    elsif temp.in? (26 ... 30)
      return 1 if hours.in? (4 .. 8)
      return 2 if hours.in? (9 .. 15)
      return 3 if hours.in? (16 .. 22)
      return 4 if hours >= 23
    end

    return 0
  end

  def self.compute_cercospora_div(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp_c = weather.avg_temp_rh_over_90 || weather.avg_temperature
    temp = (temp_c * 9/5) + 32.0

    # temp in fahrenheit
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
