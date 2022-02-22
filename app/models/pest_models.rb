module PestModels
  def calculate_p_day(min, max)
    a = 5 * p_val(min)
    b = 8 * p_val((2 * min / 3) + (max / 3))
    c = 8 * p_val((2 * max / 3) + (min / 3))
    d = 3 * p_val(min)
    (a + b + c + d) / 24.0
  end

  def p_val(temp)
    # temp in C
    return 0 if temp < 7
    return 10 * (1 - ((temp - 21)**2 / 196)) if temp.between?(7, 21) # 196 = (21-7)^2
    return 10 * (1 - ((temp - 21)**2 / 81)) if temp.between?(21, 30) # 81 = (30-21)^2
    0
  end

  # temps in celcius
  def compute_potato_p_days(weather)
    min = weather.min_temperature || 0
    max = weather.max_temperature || 0

    calculate_p_day(min, max)
  end

  # temp in celcius
  def compute_late_blight_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    late_blight_logic(temp, hours)
  end

  def late_blight_logic(temp, hours)
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
    0
  end

  def compute_carrot_foliar_dsv(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp = weather.avg_temp_rh_over_90 || weather.avg_temperature

    carrot_foliar_logic(temp, hours)
  end

  def carrot_foliar_logic(temp, hours)
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
    0
  end

  def compute_cercospora_div(weather)
    hours = weather.hours_rh_over_90 || weather.hours_rh_over_85
    return 0 if hours.nil? || hours == 0
    temp_c = weather.avg_temp_rh_over_90 || weather.avg_temperature
    temp = (temp_c * 9 / 5) + 32.0

    cercospora_logic(temp, hours)
  end

  def cercospora_logic(temp, hours)
    # temp in F
    return 0 if temp < 60
    if temp < 61
      return 0 if hours <= 21
      1
    elsif temp < 62
      return 0 if hours <= 19
      return 1 if hours <= 22
      2
    elsif temp < 63
      return 0 if hours <= 16
      return 1 if hours <= 19
      return 2 if hours <= 21
      3
    elsif temp < 64
      return 0 if hours <= 13
      return 1 if hours <= 15
      return 2 if hours <= 18
      return 3 if hours <= 20
      return 4 if hours <= 23
      5
    elsif temp < 65
      return 0 if hours <= 6
      return 1 if hours <= 8
      return 2 if hours <= 12
      return 3 if hours <= 18
      return 4 if hours <= 21
      5
    elsif temp < 71
      return 0 if hours <= 3
      return 1 if hours <= 6
      return 2 if hours <= 10
      return 3 if hours <= 14
      return 4 if hours <= 18
      return 5 if hours <= 21
      6
    elsif temp < 72
      return 0 if hours <= 2
      return 1 if hours <= 6
      return 2 if hours <= 9
      return 3 if hours <= 13
      return 4 if hours <= 17
      return 5 if hours <= 20
      6
    elsif temp < 73
      return 0 if hours <= 1
      return 1 if hours <= 6
      return 2 if hours <= 9
      return 3 if hours <= 12
      return 4 if hours <= 16
      return 5 if hours <= 19
      6
    elsif temp < 76
      return 1 if hours <= 5
      return 2 if hours <= 9
      return 3 if hours <= 11
      return 4 if hours <= 16
      return 5 if hours <= 18
      return 6 if hours <= 23
      7
    elsif temp < 77
      return 1 if hours <= 5
      return 2 if hours <= 8
      return 3 if hours <= 12
      return 4 if hours <= 15
      return 5 if hours <= 18
      return 6 if hours <= 22
      7
    elsif temp < 78
      return 1 if hours <= 5
      return 2 if hours <= 8
      return 3 if hours <= 11
      return 4 if hours <= 14
      return 5 if hours <= 17
      return 6 if hours <= 20
      7
    elsif temp < 79
      return 1 if hours <= 4
      return 2 if hours <= 7
      return 3 if hours <= 9
      return 4 if hours <= 12
      return 5 if hours <= 14
      return 6 if hours <= 17
      7
    elsif temp < 80
      return 1 if hours <= 3
      return 2 if hours <= 6
      return 3 if hours <= 8
      return 4 if hours <= 10
      return 5 if hours <= 12
      return 6 if hours <= 15
      7
    elsif temp < 81
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 6
      return 4 if hours <= 7
      return 5 if hours <= 9
      return 6 if hours <= 11
      7
    elsif temp < 82
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 5
      return 4 if hours <= 7
      return 5 if hours <= 8
      return 6 if hours <= 10
      7
    else
      return 1 if hours <= 2
      return 2 if hours <= 4
      return 3 if hours <= 5
      return 4 if hours <= 7
      return 5 if hours <= 8
      return 6 if hours <= 9
      7
    end
  end

  # implementation of equations in Carisse 2012
  # lw is the number of hours over the past 96 hours where rh > 90%
  # t is the average temperature over that time period
  def compute_botrytis_pmi(lw, t)
    # puts lw = weather.hours_rh_over_90
    # puts t = weather.avg_temp_rh_over_90 || 0
    c = 8.0
    return 0 if lw <= c
    e = 1.001 # maximum response
    f = 21.045 # location parameter proportional to the optimum temperature
    g = 0.4954 # intrinsic rate of decline from the maximum as the temperature departs from the optimum
    h = 2.1529 # degree of asymmetry of the curve
    b = 0.026
    d = 1.999
    puts e_prime = e * ((h + 1) / h) * (h ** (1 / (h + 1)))
    puts a = e_prime * Math.exp((t - f) * (g / (h + 1))) / (1 + Math.exp((t - g) * g))
    puts pmi = a * (1 - Math.exp(-1 * ((b * (lw - c)) ** d)))
    pmi
  end

  # implementation of botcast in Sutton et al 1986
  # temp in celcius
  # these conditions were read from the chart in the paper
  def compute_botcast_dinfv(lw, t)
    return 0 if lw <= 6
    return 0 if t <= 6 || t >= 28

    # dinfv = 2
    if (lw >= 22 && t <= 7) ||
      (lw >= 15 && t <= 25) ||
      (lw >= 15 && t >= 11 && t <= 16.5) ||
      (lw >= 10 && t >= 13.5 && t <= 16.5)
      return 2
    end

    # dinfv = 0
    if (lw <= 12 && t <= 9) ||
      (lw <= 15 && t >= 26) ||
      (
        ((6 <= lw) && (lw <= 12)) &&
        ((9 <= t) && (t <= 15)) &&
        ((lw - 12) < (9 - t))
      ) ||
      (lw <= 7 && t >= 24)
      return 0
    end

    return 1
  end

  def compute_botcast_dinov(lw, t)
    return 0 if t >= 30
    return 0 if lw < 5
    return 1 if lw > 12

    # the final condition requires previous day humidity and precipitation which would add a lot of complexity
    return 1
  end

  def compute_botcast_dsi(weather)
    lw = weather.hours_rh_over_90
    t = weather.avg_temp_rh_over_90 || 0
    dinov = compute_botcast_dinov(lw, t)
    dinfv = compute_botcast_dinfv(lw, t)
    dsi = dinov * dinfv
    Rails.logger.debug "Botcast: lw=#{lw}, t=#{t}, dinov=#{dinov}, dinfv=#{dinfv}, dsi=#{dsi}"
    return dsi
  end
end
