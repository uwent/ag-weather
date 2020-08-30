class Station < ApplicationRecord

  has_many :station_hourly_observations

  def observations_for_day(date)
    station_hourly_observations.where(reading_on: date)
  end

  def aggregate_observation_for_day(date)
    hours = observations_for_day(date)

    return nil if hours.empty?

    min_temp = hours.map { |h| h.min_temperature }.min
    max_temp = hours.map { |h| h.max_temperature }.max
    avg_temp = (min_temp + max_temp)/2.0
    wet_hours = hours.select { |h| h.wet_hour? }.count
    return {
      date: date,
      potato_late_blight_dsv: potato_late_blight_dsv_for(hours),
      min_temperature: min_temp.round(1),
      max_temperature: max_temp.round(1),
      avg_temperature: avg_temp.round(1),
      wet_hours: wet_hours,
      p_days: PestForecast.potato_p_days(min_temp, max_temp).round(2)
    }
  end

  def add_or_update_observation(reading_on, hour, max_temp, min_temp, rh)
    observation = station_hourly_observations.where(reading_on: reading_on,
                                                    hour: hour).first
    if observation.nil?
      station_hourly_observations <<
        StationHourlyObservation.create(reading_on: reading_on,
                                        hour: hour,
                                        max_temperature: max_temp,
                                        min_temperature: min_temp,
                                        relative_humidity: rh)
    else
      observation.max_temperature = max_temp
      observation.min_temperature = min_temp
      observation.relative_humidity = rh
      observation.save!
    end
  end

  def add_observation(reading_on, hour, max_temp, min_temp, rh)
    observation = station_hourly_observations.where(reading_on: reading_on,
                                                    hour: hour).first
    return unless observation.nil?
    station_hourly_observations <<
      StationHourlyObservation.create(reading_on: reading_on,
                                      hour: hour,
                                      max_temperature: max_temp,
                                      min_temperature: min_temp,
                                      relative_humidity: rh)
  end

  def last_reading
    station_hourly_observations.order(:reading_on).order(:hour).last
  end

  def titleized_name
    name.titleize
  end

  private
  def potato_late_blight_dsv_for hourly_observations
    wet_hours = hourly_observations.select do | observation |
      observation.wet_hour?
    end

    return 0 if wet_hours.count == 0

    wet_avg_temp = hourly_observations.map { |ob| (ob.max_temperature + ob.min_temperature)/2.0 }.sum/wet_hours.count

    return compute_potato_blight_dsv(wet_hours.count, wet_avg_temp)
  end

  def compute_potato_blight_dsv(hours, temp)
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


end
