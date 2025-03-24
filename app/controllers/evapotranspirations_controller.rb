class EvapotranspirationsController < ApplicationController
  # GET: returns ets for lat, lng, date range
  # params:
  #   lat - required, point latitude
  #   lng - required, point longitude
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, either 'in' (default) or 'mm'

  def index
    params.require([:lat, :lng])
    parse_date_or_dates || default_date_range
    index_params
    @method = params[:method]
    cumulative_value = 0

    # have to calculate from weather & insol
    if @method == "adjusted"
      weather = {}
      insols = {}
      Weather.where(@query).each { |w| weather[w.date] = w }
      Insolation.where(@query).each { |i| insols[i.date] = i }

      if weather.empty? && insols.empty?
        @status = "no data"
      else
        @dates.each do |date|
          value = if weather[date].nil? || insols[date].nil?
            0.0
          else
            EvapotranspirationCalculator.et_adj(
              avg_temp: weather[date].avg_temp,
              avg_v_press: weather[date].vapor_pressure,
              insol: insols[date].insolation,
              day_of_year: date.yday,
              lat:
            )
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
      ets = Evapotranspiration.where(@query).order(:date)

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
    @values = @data.collect { |day| day[:value] }
    @days_returned = @values.size
    @status ||= "missing days" if @days_requested != @days_returned
    @info = index_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = @info unless params[:headers] == "false"
        filename = "et data for #{lat}, #{lng}.csv"
        send_data(to_csv(@data, headers), filename:)
      end
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default first of year if end_date provided
  #   lat_range - optional, default full extent, format min,max
  #   lng_range - optional, default full extent, format min,max
  #   units - 'in' (default) or 'mm'
  #   et_method - if 'adjusted', uses new coefficients

  def grid
    parse_date_or_dates || default_single_date
    grid_params
    @adjusted_method = params[:et_method] == "adjusted"
    @data = {}

    if @adjusted_method
      weather = {}
      insols = {}
      Weather.where(@query).each { |pt| weather[[pt.latitude, pt.longitude]] = pt }
      Insolation.where(@query).each { |pt| insols[[pt.latitude, pt.longitude]] = pt }

      if weather.empty? && insols.empty?
        @status = "no data"
      else
        LandExtent.each_point do |lat, lng|
          key = [lat, lng]
          value = if weather[key].nil? || insols[key].nil?
            0.0
          else
            EvapotranspirationCalculator.et_adj(
              avg_temp: weather[key].avg_temp,
              avg_v_press: weather[key].vapor_pressure,
              insol: insols[key].insolation,
              day_of_year: weather[key].date.yday,
              lat:
            )
          end
          @data[key] = convert(value).round(5)
        end
      end
    else
      ets = Evapotranspiration.where(@query)
      if ets.exists?
        @data = ets.grid_summarize.sum(:potential_et)
        @data.each { |k, v| @data[k] = convert(v) } if @units == "mm"
      else
        @status = "no data"
      end
    end

    @values = @data.values
    @info = grid_info
    @info[:calculation_method] = @adjusted_method ? "adjusted" : "classic"

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
  #   units - optional, 'in' (default) or 'mm'
  #   scale - optional, 'min,max' for image scalebar
  #   extent - optional, 'wi' for Wisconsin only
  #   stat - optional, summarization statistic, must be sum, min, max, avg

  def map
    parse_date_or_dates || default_single_date
    map_params

    image_name = Evapotranspiration.image_name(**@image_args)
    image_type = @start_date ? "cumulative" : "daily"
    image_filename = Evapotranspiration.image_path(image_name, image_type)

    if File.exist?(image_filename)
      @url = Evapotranspiration.image_url(image_name, image_type)
      @status = "already exists"
    else
      image_name = Evapotranspiration.guess_image(**@image_args)
      if image_name
        @url = Evapotranspiration.image_url(image_name, image_type)
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
    render json: get_info(Evapotranspiration)
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
    (@units == "mm") ? UnitConverter.in_to_mm(val) : val
  end
end
