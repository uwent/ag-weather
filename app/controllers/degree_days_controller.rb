class DegreeDaysController < ApplicationController
  # GET: returns weather and computed degree days for point
  # params:
  #   lat - required, decimal latitude
  #   long - required, decimal longitude
  #   date or end_date - optional, default 1st of year. Use date for single day
  #   start_date - optional, default 1st of year
  #   Must specify one of:
  #     model - name of degree day model column (default dd_50)
  #   OR
  #     base - required, default 50F
  #     upper - optional, default none
  #     method - default sine
  #   units - default F

  def index
    parse_date_or_dates || default_date_range
    index_params
    parse_model_or_base_upper
    cumulative_value = 0

    weather = WeatherDatum.where(@query)
    if weather.exists?
      @data = weather.collect do |w|
        dd = w.degree_days(base: @base, upper: @upper, method: @method, in_f:)
        min = convert_temp(w.min_temp)
        max = convert_temp(w.max_temp)
        avg = convert_temp(w.avg_temp)
        cumulative_value += dd
        {
          date: w.date,
          min_temp: min.round(2),
          max_temp: max.round(2),
          avg_temp: avg.round(2),
          value: dd.round(3),
          cumulative_value: cumulative_value.round(2)
        }
      end
    else
      @status = "no data"
    end

    @total = cumulative_value
    @values = @data.map { |day| day[:value] }
    @days_returned = @data.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = @info unless params[:headers] == "false"
        filename = "#{@model_text} degree day data for #{lat}, #{long}.csv"
        send_data to_csv(@data, headers), filename:
      end
    end
  end

  # GET: degree-day grid for date range
  # will either return pre-calculated degree day accumulations or compute new ones
  # params:
  #   Must specify one of:
  #     model - name of degree day model column (default dd_50)
  #   OR
  #     base - default 50F, required
  #     upper - default 86F, optional
  #   units - 'F' (default) or 'C' degree days
  #   start_date - default first of year
  #   end_date - default today
  #   lat_range (min,max) - default full extent
  #   long_range (min,max) - default full extent
  #   compute=true - force computation of a custom degree day model grid (takes at least 25s)

  def grid
    parse_date_or_dates || default_date_range
    grid_params
    parse_model_or_base_upper # after grid_params
    @data = {}

    dds = DegreeDay.where(@query)
    if dds.exists?
      @days_returned = dds.where(latitude: @lat_range.min, longitude: @long_range.min).size
      @status = "missing data" if @days_returned < @days_requested - 1
      if @model
        @data = dds.grid_summarize.sum(@model)
      elsif @compute
        @status = "calculated new degree day model"
        weather = WeatherDatum.where(query)
        @data = Hash.new(0)
        weather.each do |w|
          key = [w.latitude, w.longitude]
          @data[key] += w.degree_days(base: @base, upper: @upper, in_f:)
        end
      else
        @status = "No matching pre-calculated degree-day model found, force with compute=true. Models include #{DegreeDay.models.join(", ")}"
      end
    else
      @status = "no data"
    end

    @data.each { |k, v| @data[k] = convert_dds(v) }
    @values = @data.values
    @info = grid_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.collect do |key, value|
          {latitude: key[0], longitude: key[1], value:}
        end
        headers = @info unless params[:headers] == "false"
        filename = "#{@model_text} degree day grid for #{@start_date} to #{@end_date}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: create map and return url to it
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, 'F' or 'C'
  #   scale - optional, 'min,max' for image scalebar
  #   extent - optional, omit or 'wi' for Wisconsin only
  #   stat - optional, summarization statistic, must be sum, min, max, avg
  #   model - optional, which degree day column to render, default 'dd_50'

  def map
    parse_date_or_dates || default_date_range
    map_params
    parse_model
    @image_args[:col] = @model

    image_name = DegreeDay.image_name(**@image_args)
    image_filename = DegreeDay.image_path(image_name)
    image_url = DegreeDay.image_url(image_name)

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = DegreeDay.guess_image(**@image_args)
      if image_name
        @url = image_url
        @status = "image created"
      end
    end

    @status ||= "unable to create image, invalid query or no data"

    response = {info: map_info, filename: image_name, url: @url}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.png { render html: @url ? "<img src=#{@url} height=100%>".html_safe : @status }
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
    valid_models = if models == ["all"]
      DegreeDay.model_names
    else
      (models & DegreeDay.model_names)&.sort
    end
    query = {date: dates, latitude: lat, longitude: long}

    weather = WeatherDatum.where(query).select(:date, :min_temp, :max_temp)
    dds = DegreeDay.where(query)

    if weather.empty? || dds.empty?
      status = "no data"
    else
      weather.each do |w|
        weather_data[w.date] = {
          min_temp: convert_temp(w.min_temp).round(2),
          max_temp: convert_temp(w.max_temp).round(2)
        }
      end

      valid_models.each do |m|
        total = 0
        dd_data[m] = {}
        dds.each do |dd|
          value = convert_dds(dd.send(m)) || 0
          total += value
          dd_data[m][dd.date] = {
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

  # GET: Returns info about degree day data and methods. No params.

  def info
    t = DegreeDay
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      dd_cols: DegreeDay.model_names,
      dd_methods: DegreeDaysCalculator::METHODS,
      lat_range: [t.minimum(:latitude).to_f, t.maximum(:latitude).to_f],
      long_range: [t.minimum(:longitude).to_f, t.maximum(:longitude).to_f],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - @start_time
    }
    render json: response
  end

  private

  def parse_model
    @model = params[:model]
    if @model
      if !DegreeDay.model_names.include?(@model)
        reject("Invalid model: '#{@model}'. Must be one of #{DegreeDay.model_names.join(", ")}")
      end
    else
      @model = DegreeDay.default_col.to_s
    end
  end

  def parse_model_or_base_upper
    @model = params[:model]
    @base = base
    @upper = upper
    if @upper && @upper < @base
      reject("Upper threshold '#{@upper}' must be lower than base temperature '#{@base}'")
    end
    @units = units
    @method = method
    @compute = params[:compute] == "true"

    if @model
      if !DegreeDay.model_names.include?(@model)
        reject("Invalid model: '#{@model}'. Must be one of #{DegreeDay.model_names.join(", ")}")
      end
    elsif @base
      implied_model = DegreeDay.find_model(@base, @upper, @units)
      @model = if DegreeDay.model_names.include?(implied_model)
        implied_model
      end
    else
      @model = DegreeDay.default_col.to_s
    end

    @base, @upper = DegreeDay.parse_model(@model, @units) if @model
    @model_text = "base #{@base}#{@units}"
    @model_text += ", upper #{@upper}#{@units}" if @upper
  end

  def default_date
    DegreeDayImporter.latest_date || Date.yesterday
  end

  def valid_units
    DegreeDay.valid_units
  end

  def in_f
    @units == "F"
  end

  # temps in C by default
  def convert_temp(temp)
    in_f ? UnitConverter.c_to_f(temp) : temp
  end

  # degree days in F by default
  def convert_dds(dd)
    in_f ? dd : UnitConverter.fdd_to_cdd(dd)
  end

  def units_text(*args)
    in_f ? "Fahrenheit degree days" : "Celsius degree days"
  end

  def default_base
    in_f ? DegreeDaysCalculator::BASE_F : DegreeDaysCalculator::BASE_C
  end

  def base
    params[:base].present? ? parse_float(params[:base]) : default_base
  end

  def upper
    params[:upper].present? ? parse_float(params[:upper]) : nil
  end

  def method
    DegreeDaysCalculator::METHODS.include?(params[:method]&.downcase) ? params[:method].downcase : DegreeDaysCalculator::METHOD
  end

  def models
    params[:models]&.downcase&.split(",")
  rescue
    nil
  end
end
