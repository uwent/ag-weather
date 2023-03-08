class PestForecastsController < ApplicationController
  # GET: returns pest data for dates at lat/long point
  # params:
  #   pest - required, column name of pest data
  #   lat - required, decimal latitude
  #   long - required, decimal longitude
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year

  def index
    params.require([:pest, :lat, :long])
    parse_date_or_dates || default_date_range
    index_params
    parse_pest
    cumulative_value = 0

    pfs = PestForecast.where(@query)
    if pfs.exists?
      pest_data = pfs.collect do |pf|
        [pf.date, pf.send(@pest)]
      end.to_h
      pest_data.default = 0
      weather = WeatherDatum.where(@query)
      @data = weather.collect do |w|
        value = pest_data[w.date]
        cumulative_value += value
        {
          date: w.date,
          min_temp: w.min_temp.round(2),
          max_temp: w.max_temp.round(2),
          avg_temp: w.avg_temp.round(2),
          avg_temp_hi_rh: w.avg_temp_rh_over_90,
          hours_hi_rh: w.hours_rh_over_90,
          value:,
          cumulative_value:
        }
      end
    else
      @status = "no data"
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
        @headers = @info unless params[:headers] == "false"
        filename = "point details for #{@pest} at #{lat}, #{long}.csv"
        send_data(to_csv(@data, @headers), filename:)
      end
    end
  end

  # GET: returns grid of pest data for dates
  # params:
  #   pest (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday
  #   lat_range - min,max - default whole grid
  #   long_range - min,max - default whole grid

  def grid
    params.require(:pest)
    parse_date_or_dates || default_single_date
    grid_params
    parse_pest
    @data = {}

    pfs = PestForecast.where(@query)
    if pfs.exists?
      sql = "sum(#{@pest}) as total, count(*) as count"
      pfs.grid_summarize(sql).each do |point|
        @days_returned = point.count
        key = [point.latitude, point.longitude]
        @data[key] = {
          total: point.total.round(2),
          avg: (point.total.to_f / point.count).round(2)
        }
      end
    else
      @status = "no data"
    end

    @values = @data.collect { |key, value| value[:total] }
    @info = grid_info

    response = {info: @info, data: @data}
    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = @data.map do |key, value|
          {latitude: key[0], longitude: key[1], total: value[:total], avg: value[:avg]}
        end
        headers = @info unless params[:headers] == "false"
        filename = "pest data grid for #{pest}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: returns pvy model data for dates at lat/long point
  # used by PVY predictor app, leave as is
  # params:
  #   lat (required)
  #   long (required)
  #   end_date (optional, default today)

  def pvy
    params.require([:lat, :long])

    start_date = end_date.beginning_of_year
    days_requested = (start_date..end_date).count
    days_returned = 0
    status = "OK"
    data = []
    forecast = []

    dds = DegreeDay.where(date: start_date..end_date, latitude: lat, longitude: long)
      .select(:date, :latitude, :longitude, :dd_39p2_86)

    if dds.exists?
      cum_dd = 0
      data = dds.collect do |dd|
        value = dd.dd_39p2_86
        cum_dd += value
        days_returned += 1
        {
          date: dd.date.to_s,
          dd: value.round(1),
          cum_dd: cum_dd.round(1)
        }
      end

      status = "missing data" if days_returned < days_requested - 2
      max_value = data.map { |day| day[:cum_dd] }.max

      # 7-day forecast using last 7 day average
      last_7 = data.last(7).map { |day| day[:dd] }.compact
      last_7_avg = last_7.sum / last_7.count

      cum_dd = max_value
      forecast = 1.upto(7).collect do |day|
        cum_dd += last_7_avg
        {
          date: (end_date + day.days).to_s,
          dd: last_7_avg.round(1),
          cum_dd: cum_dd.round(1)
        }
      end

      forecast_value = forecast.map { |day| day[:cum_dd] }.max
    else
      status = "no data"
    end

    info = {
      model: "PVY DD model (base 39.2F, upper 86F)",
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date:,
      end_date:,
      days_requested:,
      days_returned: days_returned,
      status:,
      compute_time: Time.current - @start_time
    }

    response = {
      info:,
      current_dds: max_value,
      future_dds: forecast_value,
      data: data.last(7),
      forecast:
    }

    render json: response
  end

  # GET: create map and return url to it
  # params:
  #   date or end_date - optional, default yesterday
  #   start_date - optional, default 1st of year
  #   units - optional, 'F' or 'C'
  #   scale - optional, 'min,max' for image scalebar
  #   extent - optional, omit or 'wi' for Wisconsin only
  #   stat - optional, summarization statistic, must be sum, min, max, avg
  #   pest - optional, which degree day column to render, default 'potato_blight_dsv'

  def map
    parse_date_or_dates || default_date_range
    map_params
    parse_pest
    @image_args[:col] = @pest

    image_name = PestForecast.image_name(**@image_args)
    image_filename = PestForecast.image_path(image_name)
    image_url = PestForecast.image_url(image_name)

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = PestForecast.guess_image(**@image_args)
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

  # GET: Pest forecasts database info. No params.

  def info
    render json: get_info(PestForecast)
  end

  private

  def parse_pest
    if params[:pest]
      if PestForecast.pests.include?(params[:pest])
        @pest = params[:pest]
      else
        reject("Invalid pest name '#{params[:pest]}'. Must be one of #{PestForecast.pests.join(", ")}")
      end
    else
      @pest = default_pest
    end
  end

  def default_pest
    PestForecast.default_col
  end

  def units
  end

  def units_text
  end
end
