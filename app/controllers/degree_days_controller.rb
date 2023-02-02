class DegreeDaysController < ApplicationController
  # GET: returns weather and computed degree days for point
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   base - default 50 F
  #   upper - default 86 F
  #   method - default sine
  #   units - default F

  def index
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    total = 0
    data = []

    weather = WeatherDatum.where(
      date: start_date..end_date,
      latitude: lat,
      longitude: long
    )

    if weather.empty?
      status = "no data"
    else
      data = weather.collect do |w|
        dd = w.degree_days(base, upper, method, in_f)
        min = in_f ? UnitConverter.c_to_f(w.min_temperature) : w.min_temperature
        max = in_f ? UnitConverter.c_to_f(w.max_temperature) : w.max_temperature
        total += dd
        {
          date: w.date,
          min_temp: min.round(1),
          max_temp: max.round(1),
          value: dd.round(1),
          cumulative_value: total.round(1)
        }
      end
    end

    values = data.map { |day| day[:value] }
    days_requested = (start_date..end_date).count
    days_returned = weather.size

    status = "missing days" if status == "OK" && days_requested != days_returned

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      days_requested:,
      days_returned:,
      base:,
      upper:,
      method:,
      units: units_text,
      min_value: values.min,
      max_value: values.max,
      total: total.round(1),
      compute_time: Time.current - start_time
    }

    response = {
      status:,
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status:}.merge(info) unless params[:headers] == "false"
        filename = "degree day data for #{lat}, #{long}.csv"
        send_data to_csv(response[:data], headers), filename:
      end
    end
  end

  # GET: Returns weather and degree day accumulations since Jan 1 of present year
  # params:
  #   lat: latitude, decimal degrees (required)
  #   long: longitude, decimal degrees (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   models: comma-separated degree day model names from pest_forecasts table - default dd_50_86
  def dd_table
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    total = 0
    data = {}

    dates = start_date..end_date

    weather = WeatherDatum.where(
      date: dates,
      latitude: lat,
      longitude: long
    ).select(:date, :min_temperature, :max_temperature)

    pest_forecasts = PestForecast.where(
      date: dates,
      latitude: lat,
      longitude: long
    )

    if weather.empty?
      status = "no data"
    else
      weather_data = {}
      weather.each do |w|
        min = convert_temp(w.min_temperature)
        max = convert_temp(w.max_temperature)
        weather_data[w.date] = {
          min_temp: min.round(2),
          max_temp: max.round(2)
        }
      end
    end

    valid_models = models & PestForecast.column_names || ["dd_50_86"]
    valid_models = valid_models&.sort

    dd_data = {}
    valid_models.each do |m|
      total = 0
      dd_data[m] = {}
      pest_forecasts.each do |pf|
        value = convert_dds(pf.send(m)) || 0
        total += value
        dd_data[m][pf.date] = {
          value: value.round(2),
          total: total.round(2)
        }
      end
    end

    # arrange weather and dds by date
    dates.each do |date|
      data[date] = weather_data[date] || {min_temp: nil, max_temp: nil}
      valid_models.each do |m|
        data[date][m] = dd_data[m][date]
      end
    end

    days_requested = dates.count
    days_returned = data.size
    status = "missing days" if status == "OK" && days_requested != days_returned

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      days_requested:,
      days_returned:,
      models: valid_models,
      units: units_text,
      compute_time: Time.current - start_time
    }

    response = {
      status:,
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
    end
  end

  # GET: Returns info about degree day data and methods. No params.

  def info
    start_time = Time.current
    t = WeatherDatum
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      dd_methods: DegreeDaysCalculator::METHODS,
      lat_range: [t.minimum(:latitude).to_f, t.maximum(:latitude).to_f],
      long_range: [t.minimum(:longitude).to_f, t.maximum(:longitude).to_f],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - start_time
    }
    render json: response
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

  # temps in C by default
  def convert_temp(temp)
    in_f ? UnitConverter.c_to_f(temp) : temp
  end

  # degree days in F by default
  def convert_dds(dd)
    in_f ? dd : UnitConverter.fdd_to_cdd(dd)
  end

  def default_date
    WeatherDatum.latest_date || Date.yesterday
  end

  def start_date
    Date.parse(params[:start_date])
  rescue
    default_date.beginning_of_year
  end

  def end_date
    Date.parse(params[:end_date])
  rescue
    default_date
  end

  def units_text
    in_f ? "Fahrenheit degree days" : "Celsius degree days"
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

  def base
    params[:base] ? params[:base].to_f : default_base
  end

  def upper
    params[:upper] ? params[:upper].to_f : default_upper
  end

  def method
    DegreeDaysCalculator::METHODS.include?(params[:method]&.downcase) ? params[:method].downcase : DegreeDaysCalculator::METHOD
  end

  def pest
    params[:pest]
  end

  def models
    params[:models]&.downcase&.split(",")
  rescue
    nil
  end
end
