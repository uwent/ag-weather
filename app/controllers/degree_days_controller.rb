class DegreeDaysController < ApplicationController
  # GET: returns weather and computed degree days for point
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   base - default 50 F
  #   upper - default none
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

    if weather.exists?
      data = weather.collect do |w|
        dd = w.degree_days(base, upper, method, in_f)
        min = convert_temp(w.min_temp)
        max = convert_temp(w.max_temp)
        total += dd
        {
          date: w.date,
          min_temp: min.round(1),
          max_temp: max.round(1),
          value: dd.round(1),
          cumulative_value: total.round(1)
        }
      end
    else
      status = "no data"
    end

    values = data.map { |day| day[:value] }
    days_requested = (start_date..end_date).count
    days_returned = data.size

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
    weather_data = {}
    dd_data = {}
    dates = start_date..end_date
    valid_models = models & PestForecast.column_names || ["dd_50_86"]
    valid_models = valid_models&.sort

    weather = WeatherDatum.where(
      date: dates,
      latitude: lat,
      longitude: long
    ).order(:date).select(:date, :min_temp, :max_temp)

    pest_forecasts = PestForecast.where(
      date: dates,
      latitude: lat,
      longitude: long
    ).order(:date)

    if weather.empty? || pest_forecasts.empty?
      status = "no data"
    else
      weather.each do |w|
        min = convert_temp(w.min_temp)
        max = convert_temp(w.max_temp)
        weather_data[w.date] = {
          min_temp: min.round(2),
          max_temp: max.round(2)
        }
      end

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

  # GET: degree-day grid for date range
  # will either return pre-calculated degree day accumulations or compute new ones
  # params:
  #   Must specify one of:
  #     model - name of degree day model column
  #   OR
  #     base - default 50F, required
  #     upper - default 86F, optional
  #   start_date - default first of year
  #   end_date - default today
  #   lat_range (min,max) - default full extent
  #   long_range (min,max) - default full extent
  #   compute=true - force computation of a custom degree day model grid (takes at least 25s)

  def grid
    start_time = Time.current
    model = params[:model]
    days_requested = (start_date..end_date).count
    days_returned = 0
    status = "OK"
    info = {}
    data = {}
    query = {
      date: start_date..end_date,
      latitude: lat_range,
      longitude: long_range
    }

    if model && DegreeDay.model_names.include?(model)
      @model = model
    else
      params.require(:base)
      implied_model = DegreeDay.find_model(params[:base], params[:upper], units)
      @model = implied_model if DegreeDay.model_names.include?(implied_model)
    end

    if @model
      dds = DegreeDay.where(query)
      if dds.exists?
        days_returned = dds.where(latitude: lat_range.min, longitude: long_range.min).size
        data = dds.grid_summarize.sum(@model)
        status = "missing data" if days_returned < days_requested - 1
      else
        status = "no data"
      end
    elsif params[:compute] == "true"
      # degree days are not pre-calculated...
      status = "calculated new degree day model"
      weather = WeatherDatum.where(query)
      days_returned = weather.where(latitude: lat_range.min, longitude: long_range.min).size
      if weather.exists?
        data = Hash.new(0)
        weather.each do |w|
          key = [w.latitude, w.longitude]
          data[key] ||= 0
          data[key] += w.degree_days(base, upper)
        end
      end
    else
      status = "No matching pre-calculated degree-day model found, force with compute=true. Models include #{DegreeDay.models.join(", ")}"
    end

    data.each { |k, v| data[k] = convert_dds(v) }
    values = data.values

    if @model
      base, upper = DegreeDay.model_to_base_upper(@model, units)
    else
      base, upper = params[:base], params[:upper]
    end

    model_text = "base: #{base}°#{units}"
    model_text += ", upper: #{upper}°#{units}" if upper

    info = {
      status:,
      model: model_text,
      units: units_text,
      start_date:,
      end_date:,
      days_requested:,
      days_returned: days_returned || 0,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      min_value: values.min,
      max_value: values.max,
      compute_time: Time.current - start_time
    }

    response = {info:, data:}

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = data.collect do |key, value|
          {
            latitude: key[0],
            longitude: key[1],
            value:
          }
        end
        headers = info unless params[:headers] == "false"
        filename = "#{@model || implied_model} data grid for #{start_date} to #{end_date}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: create map and return url to it
  # params:
  #   model

  def map
    start_time = Time.current

    @end_date = params[:date].present? ? date : end_date
    @start_date = start_date(@end_date.beginning_of_year)
    @start_date = nil if @start_date == @end_date
    @model = params[:model] || "dd_50"
    @min_value = params[:min_value]
    @max_value = params[:max_value]
    @extent = params[:extent]
    @image_args = {
      model: @model,
      start_date: @start_date,
      end_date: @end_date,
      units:,
      min_value: @min_value,
      max_value: @max_value,
      extent: @extent
    }.compact

    image_name, _ = DegreeDay.image_attr(**@image_args)
    image_filename = DegreeDay.image_path(image_name)
    image_url = DegreeDay.image_url(image_name)

    @status = "unable to create image, invalid query or no data"

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = DegreeDay.create_image(**@image_args)
      if image_name
        @url = image_url
        @status = "image created"
      end
    end

    if request.format.png?
      render html: @url ? "<img src=#{@url} height=100%>".html_safe : @status
    else
      render json: {
        info: {
          status: @status,
          model: @model,
          start_date: @start_date,
          end_date: @end_date,
          units: @units,
          compute_time: Time.current - start_time
        },
        map: @url
      }
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

  def units
    unit = params[:units]&.upcase || DegreeDay.valid_units[0]
    if DegreeDay.valid_units.include?(unit)
      unit
    else
      reject("Invalid unit '#{unit}'. Must be one of #{DegreeDay.valid_units.join(", ")}.")
    end
  end

  def in_f
    units == "F"
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

  def units_text
    in_f ? "Fahrenheit degree days" : "Celsius degree days"
  end

  def default_base
    in_f ? DegreeDaysCalculator::BASE_F : DegreeDaysCalculator::BASE_C
  end

  def default_upper
    nil
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
