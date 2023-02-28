class EvapotranspirationsController < ApplicationController

  # GET: returns ets for lat, long, date range
  # params:
  #   lat - required, point latitude
  #   long - required, point longitude
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, either 'in' (default) or 'mm'

  def index
    parse_date_or_dates || default_date_range
    index_params
    @method = params[:method]
    cumulative_value = 0

    # have to calculate from weather & insol
    if @method == "adjusted"
      weather = {}
      insols = {}
      WeatherDatum.where(@query).each { |w| weather[w.date] = w }
      Insolation.where(@query).each { |i| insols[i.date] = i }

      if weather.empty? && insols.empty?
        @status = "no data"
      else
        @dates.each do |date|
          if weather[date].nil? || insols[date].nil?
            value = 0
          else
            t = weather[date].avg_temp
            vp = weather[date].vapor_pressure
            i = insols[date].insolation
            d = date.yday
            l = lat
            value = EvapotranspirationCalculator.et_adj(t, vp, i, d, l)
          end
          value = convert(value)
          cumulative_value += value
          @data << {
            date:,
            value: value.round(5),
            cumulative_value: cumulative_value.round(5)
          }
        end
      end
    else
      ets = Evapotranspiration.where(@query)

      if ets.empty?
        @status = "no data"
      else
        @data = ets.collect do |et|
          date = et.date.to_s
          value = convert(et.potential_et)
          cumulative_value += value
          {
            date:,
            value: value.round(5),
            cumulative_value: cumulative_value.round(5)
          }
        end
      end
    end

    @total = cumulative_value
    @values = @data.map { |day| day[:value] }
    @days_returned = @values.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = @info unless params[:headers] == "false"
        filename = "et data for #{lat}, #{long}.csv"
        send_data(to_csv(@data, headers), filename:)
      end
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default first of year if end_date provided
  #   lat_range - optional, default full extent, format min,max
  #   long_range - optional, default full extent, format min,max
  #   units - 'MJ' (default) or 'KWh'

  def grid
    parse_date_or_dates || default_single_date
    grid_params
    @data = {}

    ets = Evapotranspiration.where(@query)
    if ets.exists?
      @days_returned = ets.where(latitude: @lat_range.min, longitude: @long_range.min).size
      @data = ets.grid_summarize.sum(:potential_et)
      @data.each { |k, v| @data[k] = convert(v) } if @units == "mm"
      @status = "missing days" if @days_returned < @days_requested
    else
      @status = "no data"
    end

    @values = @data.values
    @info = grid_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.map do |key, value|
          {latitude: key[0], longitude: key[1], value:}
        end
        headers = @info unless params[:headers] == "false"
        filename = "et data grid (#{@units}) for #{@date}.csv"
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

  def map
    parse_date_or_dates || default_single_date
    map_params

    image_name = Evapotranspiration.image_name(**@image_args)
    image_filename = Evapotranspiration.image_path(image_name)
    image_url = Evapotranspiration.image_url(image_name)

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = Evapotranspiration.guess_image(**@image_args)
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

  # GET: Returns info about et database

  def info
    start_time = Time.current
    t = Evapotranspiration
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      table_cols: t.column_names,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      value_range: [t.minimum(:potential_et), t.maximum(:potential_et)],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - start_time
    }
    render json: response
  end

  private

  def default_date
    EvapotranspirationDataImport.latest_date || Date.yesterday
  end

  def valid_units
    Evapotranspiration.valid_units
  end

  def units_text
    "#{@units}/day"
  end

  # stored in 'in'
  def convert(val)
    @units == "mm" ? UnitConverter.in_to_mm(val) : val
  end
end
