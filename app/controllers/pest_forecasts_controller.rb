class PestForecastsController < ApplicationController

  # GET: returns pest data for dates at lat/long point
  # params:
  #   pest (required)
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday

  def index
    params.require([:pest, :lat, :long])

    start_time = Time.current
    days_requested = (start_date..end_date).count
    days_returned = 0
    status = "OK"
    info = {}
    data = []

    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(
        date: start_date..end_date,
        latitude: lat,
        longitude: long
      )

      if forecasts.exists?
        pest_data = forecasts.collect do |pf|
          [pf.date, pf.send(pest)]
        end.to_h
        pest_data.default = 0
        cum_value = 0

        weather = WeatherDatum.where(date: start_date..end_date, latitude: lat, longitude: long)
        data = weather.collect do |w|
          value = pest_data[w.date]
          cum_value += value
          days_returned += 1
          {
            date: w.date,
            min_temp: w.min_temp.round(1),
            max_temp: w.max_temp.round(1),
            avg_temp: w.avg_temp.round(1),
            avg_temp_hi_rh: w.avg_temp_rh_over_90,
            hours_hi_rh: w.hours_rh_over_90,
            value: value.round(1),
            cumulative_value: cum_value.round(1)
          }
        end
        status = "missing data" if days_returned < days_requested - 1
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    # values = data.map { |d| d[:value] }

    info = {
      pest:,
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date:,
      end_date:,
      units: {
        weather: "C",
        degree_days: "F"
      },
      cumulative_value: cum_value.round(1),
      days_requested:,
      days_returned:,
      status:,
      compute_time: Time.current - start_time
    }

    response = {
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status:}.merge(info) unless params[:headers] == "false"
        filename = "point details for #{pest} at #{lat}, #{long}.csv"
        send_data(to_csv(response[:data], headers), filename:)
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

  def get_grid
    params.require(:pest)

    start_time = Time.current
    days_requested = (start_date..end_date).count
    status = "OK"
    info = {}
    data = []
    days_returned = 0

    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(
        date: start_date..end_date,
        latitude: lat_range,
        longitude: long_range
      )

      if forecasts.empty?
        status = "no data"
      else
        data = forecasts.grid_summarize("sum(#{pest}) as total, count(*) as count")
          .collect do |point|
          days_returned = point.count
          {
            lat: point.latitude.to_f.round(1),
            long: point.longitude.to_f.round(1),
            total: point.total.round(2),
            avg: (point.total.to_f / point.count).round(2)
          }
        end
        status = "missing data" if days_returned < days_requested - 2
      end
    else
      status = "pest not found"
    end

    values = data.map { |d| d[:total] }

    info = {
      pest:,
      start_date:,
      end_date:,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      min_value: values.min,
      max_value: values.max,
      days_requested:,
      days_returned:,
      status:,
      compute_time: Time.current - start_time
    }

    response = {
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = info unless params[:headers] == "false"
        filename = "pest data grid for #{pest}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: returns degree day data for dates at lat/long point
  # params:
  #   lat (required) - degrees north
  #   long (required) - positive degrees west
  #   t_base - degrees F, default 50
  #   t_upper - degrees F, default 86
  #   start_date - default 1st of year
  #   end_date - default today
  #   in_f - default true (fahrenheit or celsius units)

  def custom_point_details
    params.require([:lat, :long])

    start_time = Time.current
    days_requested = (start_date..end_date).count
    days_returned = 0
    status = "OK"
    info = {}
    data = []

    weather = WeatherDatum.where(
      date: start_date..end_date,
      latitude: lat,
      longitude: long
    )

    cum_value = 0
    if weather.empty?
      status = "no data"
    else
      data = weather.collect do |w|
        value = w.degree_days(t_base, t_upper)
        cum_value += value
        days_returned += 1
        {
          date: w.date,
          min_temp: w.min_temp.round(1),
          max_temp: w.max_temp.round(1),
          avg_temp: w.avg_temp.round(1),
          value: value.round(1),
          cumulative_value: cum_value.round(1)
        }
      end
      status = "missing data" if days_returned < days_requested - 2
    end

    info = {
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date:,
      end_date:,
      t_base:,
      t_upper:,
      units: {weather: "C", degree_days: "F"},
      days_requested:,
      days_returned: days_returned,
      status:,
      compute_time: Time.current - start_time
    }

    response = {
      info:,
      data:
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status:}.merge(info) unless params[:headers] == "false"
        filename = "degree day data for #{lat}, #{long}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: returns pvy model data for dates at lat/long point
  # params:
  #   lat (required)
  #   long (required)
  #   end_date (optional, default today)

  def pvy
    params.require([:lat, :long])

    start_time = Time.current
    start_date = end_date.beginning_of_year
    days_requested = (start_date..end_date).count
    days_returned = 0
    status = "OK"
    data = []
    forecast = []

    dds = DegreeDay.where(date: start_date..end_date, latitude: lat, longitude: long)
      .select(:date, :latitude, :longitude, :dd_39p2_86)

    if dds.empty?
      status = "no data"
    else
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
    end

    info = {
      model: "PVY DD model (base 39.2F, upper 86F)",
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date:,
      end_date:,
      days_requested:,
      days_returned: days_returned || 0,
      status:,
      compute_time: Time.current - start_time
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

  

  # GET: generates and returns a pest map
  # id: the column name from PestForecasts
  # start_date - default 1st of year
  # end_date - default most recent data
  # units (if dd map)

  def show
    start_time = Time.current
    parse_map_params

    status = "OK"
    dd_params = {}
    image_dir = File.join(ImageCreator.file_dir, PestForecast.pest_map_dir)
    url_prefix = ImageCreator.url_path + "/" + PestForecast.pest_map_dir

    if PestForecast.all_models.include?(@model)
      if PestForecast.pest_models.include?(@model)
        _, image_name = PestForecast.pest_map_attr(@model, @start_date, @end_date, @min_value, @max_value, @wi_only)
        image_filename = File.join(image_dir, image_name)
        Rails.logger.debug "Looking for #{image_filename}"
        unless File.exist? image_filename
          image_name = PestForecast.create_pest_map(@model, @start_date, @end_date, @min_value, @max_value, @wi_only)
        end
      else
        _, image_name, base, upper = PestForecast.dd_map_attr(@model, @start_date, @end_date, @units, @min_value, @max_value, @wi_only)
        dd_params = {base:, upper:, units: @units}
        image_filename = File.join(image_dir, image_name)
        Rails.logger.debug "Looking for #{image_filename}"
        unless File.exist? image_filename
          image_name = PestForecast.create_dd_map(@model, @start_date, @end_date, @units, @min_value, @max_value, @wi_only)
        end
      end
      if image_name == "no_data.png"
        status = "ERR: No data"
        url = "/no_data.png"
      else
        url = "#{url_prefix}/#{image_name}"
      end
    else
      status = "ERR: Model '#{@model}' not found, must be one of: #{PestForecast.all_models.join(", ")}"
      url = "/no_data.png"
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: {
        status:,
        params: {
          model: @model,
          start_date: @start_date,
          end_date: @end_date
        }.merge(dd_params),
        compute_time: Time.current - start_time,
        map: url
      }
    end
  end

  # GET: Pest forecasts database info. No params.

  def info
    start_time = Time.current
    t = PestForecast
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      pest_names: t.all_models,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      missing_days: all_dates - actual_dates,
      compute_time: Time.current - start_time
    }
    render json: response
  end

  private

  def parse_map_params
    earliest_date = PestForecast.earliest_date || Date.current.beginning_of_year
    latest_date = PestForecast.latest_date || default_date
    @model = params[:id]
    @end_date = [end_date, latest_date].min
    @start_date = start_date.clamp(earliest_date, @end_date)
    @units = %w[F C].include?(params[:units]) ? params[:units] : "F"
    @min_value = params[:min_value].present? ? parse_number(params[:min_value]) : nil
    @max_value = params[:max_value].present? ? parse_number(params[:max_value]) : nil
    @wi_only = params[:wi_only] == "true"
  end

end
