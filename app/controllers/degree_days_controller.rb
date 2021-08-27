class DegreeDaysController < ApplicationController

  # This was never implemented and doesn't generate any map images.
  # def show
  #   @map = "path/to/degree_day/map.img"

  #   degree_day_maps = [
  #     { type: 'alfalfa_weevil', map: @map },
  #     { type: 'corn_development', map: @map },
  #     { type: 'corn_stalk_borer', map: @map },
  #     { type: 'cranberry', map: @map },
  #     { type: 'euro_corn_borer', map: @map },
  #     { type: 'potato', map: @map },
  #     { type: 'seedcorn_maggot', map: @map },
  #     { type: 'tree_pests', map: @map }
  #   ]

  #   render json: degree_day_maps
  # end

  # GET: params lat, long, start_date, end_date, base, upper, method, units
  def index
    weather = WeatherDatum.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(date: :asc)

    info = {
      lat: lat,
      long: long,
      start_date: start_date,
      end_date: end_date,
      days: weather.count,
      base_temp: base_temp,
      upper_temp: upper_temp,
      method: method,
      units: units_text
    }

    total = 0
    degree_days = []

    # weather temps in C, but returns Fahrenheit dds
    degree_days = weather.collect do |w|
      dd = w.degree_days(base_temp, upper_temp, method)
      total += dd
      {
        date: w.date,
        min_temp: (in_f ? DegreeDaysCalculator.c_to_f(w.min_temperature) : w.min_temperature).round(1),
        max_temp: (in_f ? DegreeDaysCalculator.c_to_f(w.max_temperature) : w.max_temperature).round(1),
        value: dd.round(1),
        cumulative_value: total.round(1)
      }
    end

    render json: {
      info: info,
      data: degree_days
    }
  end

  def info
    t = WeatherDatum
    render json: {
      date_range: [t.minimum(:date).to_s, t.maximum(:date).to_s],
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      dd_methods: DegreeDaysCalculator::METHODS
    }
  end

  private

  def in_f
    case params[:units]
    when "F", "f"
      true
    when "C", "c"
      false
    else
      true
    end
  end

  def units_text
    in_f ? "Fahrenheit" : "Celcius"
  end

  def default_base
    in_f ? DegreeDaysCalculator::BASE_F : DegreeDaysCalculator::BASE_C
  end

  def default_upper
    in_f ? DegreeDaysCalculator::UPPER_F : DegreeDaysCalculator::UPPER_C
  end

  def lat
    params[:lat] ? params[:lat].to_d.round(1) : nil
  end

  def long
    params[:long] ? params[:long].to_d.round(1) : nil
  end
  
  def start_date
    begin
      params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
    rescue
      Date.current.beginning_of_year
    end
  end

  def end_date
    begin
      params[:end_date] ? Date.parse(params[:end_date]) : Date.current
    rescue
      Date.current
    end
  end

  def base_temp
    params[:base_temp] ? params[:base_temp].to_f : default_base
  end

  def upper_temp
    params[:upper_temp] ? params[:upper_temp].to_f : default_upper
  end

  def method
    DegreeDaysCalculator::METHODS.include?(params[:method]) ? params[:method] : DegreeDaysCalculator::METHOD
  end

  def pest
    params[:pest]
  end


    # def latitude
    #   params[:latitude].nil? ? Wisconsin.min_lat : params[:latitude]
    # end

    # def longitude
    #   params[:longitude].nil? ? Wisconsin.min_long : params[:longitude]
    # end
end
