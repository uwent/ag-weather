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
    elsif temp.in? (15.556 ... 26.667)
      return 1 if hours.in? (10 .. 12)
      return 2 if hours.in? (13 .. 15)
      return 3 if hours.in? (16 .. 18)
      return 4 if hours.in? (19 .. 21)
    end
    return 0
  end

  def compute_carrot_foliar_dsv(weather)
    temp =  weather.avg_temperature
    hours = weather.hours_rh_over_85

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

  def self.potato_blight_severity(seven_day, season)
    if seven_day <= 3 && season < 30
      return 0
    elsif seven_day > 21
      return 4
    elsif seven_day >= 3 || season >= 30
      return 2
    end
  end

  def self.carrot_foliar_severity(total)
    if total >= 20
      return 4
    elsif total >= 15
      return 3
    elsif total >= 10
      return 2
    elsif total >= 5
      return 1
    else
      return 0
    end
  end

  def self.carrot_foliar_severity_for(start_date, end_date)
    dsvs = select("latitude, longitude, sum(carrot_foliar_dsv) as total")
      .where('date >= ? and date <= ?', start_date, end_date)
      .group(:latitude, :longitude)

    return dsvs.collect do |dsv|
      { lat: dsv.latitude, long: dsv.longitude * -1,
        severity: carrot_foliar_severity(dsv.total)
      }
    end
  end

  def self.potato_blight_severity_for(end_date)
    season_land_grid = land_grid_of_potato_sum_for_dates(end_date.beginning_of_year,
                                                         end_date)
    week_land_grid = land_grid_of_potato_sum_for_dates(end_date - 7.days,
                                                       end_date)

    dsvs = []
    Wisconsin.each_point do |lat, long|
      dsvs <<  { lat: lat.round(1), long: long.round(1) * -1,
                severity: potato_blight_severity(week_land_grid[lat, long],
                                                 season_land_grid[lat, long])
      }
    end

    return dsvs
  end

  def self.for_lat_long_date_range(lat, long, start_date, end_date)
    where(latitude: lat)
      .where(longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date)
      .order(date: :desc)
  end

  private
  def self.land_grid_of_potato_sum_for_dates(start_date, end_date)
    grid = LandGrid.wisconsin_grid
    select("latitude, longitude, sum(potato_blight_dsv) as total")
      .where('date >= ? and date <= ?', start_date, end_date)
      .group(:latitude, :longitude).each do |dsv|
      grid[dsv.latitude, dsv.longitude] = dsv.total
    end

    return grid
  end
end
