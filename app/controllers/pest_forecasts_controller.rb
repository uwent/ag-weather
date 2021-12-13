class PestForecastsController < ApplicationController
  # GET: returns grid of pest data for dates
  # params:
  #   pest (required)
  #   start_date
  #   end_date
  #   lat_range - min,max
  #   long_range - min,max

  def index
    start_time = Time.current
    days_requested = (start_date..end_date).count
    status = "OK"
    info = {}
    data = []

    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(latitude: lat_range, longitude: long_range)
        .where(date: start_date..end_date)

      days_returned = forecasts.distinct.count(:date)
      status = "missing data" if days_returned < days_requested - 2

      if forecasts.size > 0
        data = forecasts.group(:latitude, :longitude)
          .order(:latitude, :longitude)
          .select(:latitude, :longitude, "sum(#{pest}) as total")
          .collect do |point|
          {
            lat: point.latitude.to_f.round(1),
            long: point.longitude.to_f.round(1),
            total: point.total.round(2),
            avg: (point.total.to_f / days_returned).round(2)
          }
        end
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    values = data.map { |d| d[:total] }

    info = {
      pest: pest,
      start_date: start_date,
      end_date: end_date,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      min_value: values.min,
      max_value: values.max,
      days_requested: days_requested,
      days_returned: days_returned || 0,
      status: status,
      compute_time: Time.current - start_time
    }

    response = {
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = info unless params[:headers] == "false"
        filename = "pest data grid for #{pest}.csv"
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: degree-day grid for date range

  # params (if pest):
  #   pest (required) - column name from pest_forecasts
  #   start_date - default 1st of year
  #   end_date - default today
  #   lat_range - min,max
  #   long_range - min,max

  # params (if no pest, degree days are computed from weather):
  #   start_date - default first of year
  #   end_date - default today
  #   t_base - default 50F
  #   t_upper - default 86F
  #   lat_range (min,max) - default full extent
  #   long_range (min,max) - default full extent

  def custom
    start_time = Time.current
    days_requested = (start_date..end_date).count
    status = "OK"
    info = {}
    weather_info = {}
    data = []

    if pest
      if PestForecast.column_names.include?(pest)
        pest_data = PestForecast.where(date: start_date..end_date)
          .where(latitude: lat_range, longitude: long_range)

        days_returned = pest_data.distinct.count(:date)
        status = "missing data" if days_returned < days_requested - 2

        if pest_data.size > 0
          data = pest_data.group(:latitude, :longitude)
            .order(:latitude, :longitude)
            .select(:latitude, :longitude, "sum(#{pest}) as total")
            .collect do |point|
            {
              lat: point.latitude.to_f.round(1),
              long: point.longitude.to_f.round(1),
              total: point.total.round(2)
            }
          end
        else
          status = "pest not found"
        end
      else
        status = "no data"
      end
    else
      weather = WeatherDatum.where(date: start_date..end_date)
        .where(latitude: lat_range, longitude: long_range)

      dates = weather.distinct.pluck(:date)
      days_returned = dates.size
      status = "missing data" if days_returned < days_requested - 2

      weather_info = {
        t_base: t_base,
        t_upper: t_upper,
        units: "Fahrenheit degree days"
      }

      if weather.size > 0
        grid = weather.each_with_object(Hash.new(0)) do |w, h|
          coord = [w.latitude.to_f, w.longitude.to_f]
          if h[coord].nil?
            h[coord] = w.degree_days(t_base, t_upper)
          else
            h[coord] += w.degree_days(t_base, t_upper)
          end
          h
        end
        grid.keys.each do |coord|
          data << {
            lat: coord.first,
            long: coord.last,
            total: grid[coord].round(2)
          }
        end
      else
        status = "no data"
      end
    end

    values = data.map { |d| d[:total] }

    info = {
      pest: pest || "degree day model",
      start_date: start_date,
      end_date: end_date,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size
    }
      .merge(weather_info)
      .merge({
        min_value: values.min,
        max_value: values.max,
        days_requested: days_requested,
        days_returned: days_returned || 0,
        status: status,
        compute_time: Time.current - start_time
      })

    response = {
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status: status}.merge(info) unless params[:headers] == "false"
        filename = if pest
          "#{pest} data grid for #{start_date} to #{end_date}.csv"
        else
          "degree day grid for #{start_date} to #{end_date}.csv"
        end
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: returns pest data for dates at lat/long point
  # params:
  #   pest (required)
  #   lat (required)
  #   long (required)
  #   start_date
  #   end_date

  def point_details
    start_time = Time.current
    days_requested = (start_date..end_date).count
    status = "OK"
    info = {}
    data = []

    if PestForecast.column_names.include?(pest)
      forecasts = PestForecast.where(latitude: lat, longitude: long)
        .where(date: start_date..end_date)
        .order(:date)
        .map { |pf| [pf.date, pf.send(pest)] }.to_h
      forecasts.default = 0

      days_returned = forecasts.size
      status = "missing data" if days_returned < days_requested - 2

      cum_value = 0
      if forecasts.size > 0
        data = WeatherDatum.where(latitude: lat, longitude: long)
          .where(date: start_date..end_date)
          .order(:date)
          .collect do |w|
          value = forecasts[w.date]
          cum_value += value
          {
            date: w.date,
            min_temp: w.min_temperature.round(1),
            max_temp: w.max_temperature.round(1),
            avg_temp: w.avg_temperature.round(1),
            avg_temp_hi_rh: w.avg_temp_rh_over_90,
            hours_hi_rh: w.hours_rh_over_90,
            value: value.round(1),
            cumulative_value: cum_value.round(1)
          }
        end
      else
        status = "no data"
      end
    else
      status = "pest not found"
    end

    # values = data.map { |d| d[:value] }

    info = {
      pest: pest,
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date: start_date,
      end_date: end_date,
      units: {weather: "C", degree_days: "F"},
      cumulative_value: cum_value.round(1),
      days_requested: days_requested,
      days_returned: days_returned || 0,
      status: status,
      compute_time: Time.current - start_time
    }

    response = {
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status: status}.merge(info) unless params[:headers] == "false"
        filename = "point details for #{pest} at #{lat}, #{long}.csv"
        send_data to_csv(response[:data], headers), filename: filename
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
  #   in_f - default true (fahrenheit or celcius units)

  def custom_point_details
    start_time = Time.current
    days_requested = (start_date..end_date).count
    status = "OK"
    info = {}
    data = []

    weather = WeatherDatum.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    days_returned = weather.size
    status = "missing data" if days_returned < days_requested - 2

    cum_value = 0
    if weather.size > 0
      data = weather.collect do |w|
        value = w.degree_days(t_base, t_upper)
        cum_value += value
        {
          date: w.date,
          min_temp: w.min_temperature.round(1),
          max_temp: w.max_temperature.round(1),
          avg_temp: w.avg_temperature.round(1),
          value: value.round(1),
          cumulative_value: cum_value.round(1)
        }
      end
    else
      status = "no data"
    end

    info = {
      lat: lat.to_f.round(1),
      long: long.to_f.round(1),
      start_date: start_date,
      end_date: end_date,
      t_base: t_base,
      t_upper: t_upper,
      units: {weather: "C", degree_days: "F"},
      days_requested: days_requested,
      days_returned: days_returned || 0,
      status: status,
      compute_time: Time.current - start_time
    }

    response = {
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status: status}.merge(info) unless params[:headers] == "false"
        filename = "degree day data for #{lat}, #{long}.csv"
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: returns pvy model data for dates at lat/long point
  # params:
  #   lat (required)
  #   long (required)
  #   end_date (optional, default today)

  def pvy
    start_time = Time.current
    start_date = end_date.beginning_of_year
    days_requested = (start_date..end_date).count
    status = "OK"
    data = []
    forecast = []

    forecasts = PestForecast.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    days_returned = forecasts.size
    status = "missing data" if days_returned < days_requested - 2

    if forecasts.size > 0
      cum_dd = 0
      data = forecasts.collect do |pf|
        dd = pf.dd_39p2_86
        cum_dd += dd
        {
          date: pf.date.to_s,
          dd: dd.round(1),
          cum_dd: cum_dd.round(1)
        }
      end

      max_value = data.map { |day| day[:cum_dd] }.max

      # 7-day forecast using last 7 day average
      last_7 = data.last(7).map { |day| day[:dd] }
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
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned || 0,
      status: status,
      compute_time: Time.current - start_time
    }

    response = {
      info: info,
      current_dds: max_value,
      future_dds: forecast_value,
      data: data.last(7),
      forecast: forecast
    }

    render json: response
  end

  # GET: returns grid of pest data for dates
  # params:
  #   start_date
  #   end_date
  #   lat_range - min,max
  #   long_range - min,max

  def freeze
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    forecasts = PestForecast.where(date: start_date..end_date)

    if forecasts.size > 0
      data = forecasts.where(freeze: true)
        .group(:latitude, :longitude)
        .order(:latitude, :longitude)
        .count
        .map do |point|
        {
          lat: point[0][0].to_f.round(1),
          long: point[0][1].to_f.round(1),
          freeze: point[1]
        }
      end
    else
      status = "no data"
    end

    info = {
      start_date: start_date,
      end_date: end_date,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      status: status,
      compute_time: Time.current - start_time
    }

    response = {
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = info unless params[:headers] == "false"
        filename = "pest data grid for #{pest}.csv"
        send_data to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: generates and returns a pest map
  # id: the column name from PestForecasts
  # start_date
  # end_date
  # units (if dd map)

  def show
    start_time = Time.current
    parse_map_params()

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
        dd_params = {base: base, upper: upper, units: @units}
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
        puts url = "#{url_prefix}/#{image_name}"
      end
    else
      status = "ERR: Model '#{@model}' not found, must be one of: #{PestForecast.all_models.join(", ")}"
      url = "/no_data.png"
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: {
        status: status,
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

  # Pest forecasts database info. No params.
  def info
    pf = PestForecast
    response = {
      pest_names: pf.all_models,
      date_range: [pf.minimum(:date).to_s, pf.maximum(:date).to_s],
      total_days: pf.distinct.pluck(:date).count,
      lat_range: [pf.minimum(:latitude).to_f, pf.maximum(:latitude).to_f],
      long_range: [pf.minimum(:longitude).to_f, pf.maximum(:longitude).to_f]
    }

    render json: response
  end

  private

  # def check_hard_freeze
  #   nov_1 = Date.new(end_date.year, 11, 1)

  #   return {} if end_date < nov_1
  #   WeatherDatum.select(:latitude, :longitude)
  #     .distinct
  #     .where(date: nov_1..end_date)
  #     .where("min_temperature < ?", -2.22)
  #     .order(:latitude, :longitude)
  #     .collect { |w| {"#{w.latitude},#{w.longitude}" => true} }
  #     .inject({}, :merge)
  # end

  # def build_cumulative_dd(weather, date, t_base, t_upper)
  #   degree_days = []
  #   weather.select { |day| date >= day.date }
  #     .each do |w|
  #       degree_days << w.degree_days(t_base, t_upper)
  #     end
  #   degree_days.sum
  # end

  def start_date
    parse_date(params[:start_date], Date.current.beginning_of_year)
  end

  def end_date
    parse_date(params[:end_date], Date.current)
  end

  def parse_map_params
    @model = params[:id]
    @end_date = [end_date, PestForecast.latest_date].min
    @start_date = [start_date, @end_date].min
    @units = %w[F C].include?(params[:units]) ? params[:units] : "F"
    @min_value = params[:min_value].present? ? parse_number(params[:min_value]) : nil
    @max_value = params[:max_value].present? ? parse_number(params[:max_value]) : nil
    @wi_only = params[:wi_only] == "true"
  end

  def parse_number(s)
    s !~ /\D/ ? s.to_i : nil
  end

  def lat
    params[:lat].to_d.round(1)
  end

  def long
    params[:long].to_d.round(1)
  end

  def lat_range
    parse_coords(params[:lat_range], LandExtent.latitudes)
  end

  def long_range
    parse_coords(params[:long_range], LandExtent.longitudes)
  end

  def pest
    params[:pest]
  end

  def t_base
    params[:t_base].present? ? params[:t_base].to_f : DegreeDaysCalculator::BASE_F
  end

  def t_upper
    params[:t_upper].present? ? params[:t_upper].to_f : PestForecast::NO_MAX
  end

  def parse_date(param, default)
    param ? Date.parse(param) : default
  rescue
    default
  end

  def parse_coord(param, default)
    param.present? ? param.to_f.round(1) : default
  rescue
    default
  end

  def parse_coords(param, default)
    param.present? ? param.split(",").map(&:to_f).sort.inject { |a, b| a.round(1)..b.round(1) } : default
  rescue
    default
  end
end
