class EvapotranspirationsController < ApplicationController
  # GET: returns ets for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today

  def index
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    data = []

    conditions = {date: start_date..end_date, latitude: lat, longitude: long}

    if params[:method] == "adjusted"
      weather = {}
      insols = {}
      WeatherDatum.where(conditions).each { |w| weather[w.date] = w }
      Insolation.where(conditions).each { |i| insols[i.date] = i }

      if weather.empty? || insols.empty?
        status = "no data"
      else
        data = []
        cumulative_value = 0
        start_date.upto(end_date) do |date|
          Rails.logger.debug "\n#{date}"
          next if weather[date].nil? || insols[date].nil?
          t = weather[date].avg_temperature
          vp = weather[date].vapor_pressure
          i = insols[date].insolation
          d = date.yday
          l = lat

          reg = EvapotranspirationCalculator.et(t, vp, i, d, l)
          adj = EvapotranspirationCalculator.et_adj(t, vp, i, d, l)
          # Rails.logger.debug "> classic: #{reg}\n> adjusted: #{adj}\n> diff: #{(100 * (adj - reg) / reg).round(1)}%"

          value = (params[:method] == "adjusted") ? adj : reg
          cumulative_value += value
          data << {date:, value:, cumulative_value:}
        end
      end
    else
      ets = Evapotranspiration.where(conditions)

      if ets.empty?
        status = "no data"
      else
        cumulative_value = 0
        data = ets.collect do |et|
          date = et.date.to_formatted_s
          value = et.potential_et
          cumulative_value += value
          {date:, value:, cumulative_value:}
        end
      end
    end

    values = data.map { |day| day[:value] }
    days_requested = (start_date..end_date).count
    days_returned = values.size

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      days_requested:,
      days_returned:,
      min_value: values.min,
      max_value: values.max,
      units: "in/day",
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && days_requested != days_returned

    response = {status:, info:, data:}

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = {status:}.merge(info) unless params[:headers] == "false"
        filename = "et data for #{lat}, #{long}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: create map and return url to it

  def show
    start_time = Time.current

    @date = [date_from_id, default_date].min
    if params[:start_date].present?
      latest_date = Evapotranspiration.latest_date || default_date
      @date = [@date, latest_date].min
      @start_date = [[start_date, earliest_date].max, @date].min
      @start_date = nil if @start_date == @date
    end
    @units = units

    image_name = Evapotranspiration.image_name(@date, @start_date, @units)
    image_filename = File.join(ImageCreator.file_dir, image_name)

    if File.exist?(image_filename)
      url = File.join(ImageCreator.url_path, image_name)
    else
      image_name = Evapotranspiration.create_image(@date, start_date: @start_date, units: @units)
      url = (image_name == "no_data.png") ? "/no_data.png" : File.join(ImageCreator.url_path, image_name)
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: {
        params: {
          start_date: @start_date,
          end_date: @date,
          units: @units
        },
        compute_time: Time.current - start_time,
        map: url
      }
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date - default most recent date

  def all_for_date
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    @date = date

    ets = Evapotranspiration.where(date: @date)

    if ets.empty?
      status = "no data"
    else
      data = ets.collect do |et|
        {
          lat: et.latitude.to_f.round(1),
          long: et.longitude.to_f.round(1),
          value: et.potential_et.round(3)
        }
      end
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq
    values = data.map { |d| d[:value] }

    info = {
      date:,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      grid_points: lats.count * longs.count,
      min_value: values.min,
      max_value: values.max,
      units: "Potential evapotranspiration (in/day)",
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
        filename = "et data grid for #{@date}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: calculate et with arguments

  def calculate_et
    render json: {
      inputs: params,
      value: Evapotranspiration.new.potential_et
    }
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

  def earliest_date
    Evapotranspiration.earliest_date || Date.current.beginning_of_year
  end

  def units
    valid_units = Evapotranspiration::UNITS
    if valid_units.include?(params[:units])
      params[:units]
    elsif !params[:units].present?
      valid_units.first
    else
      raise ActionController::BadRequest.new("Invalid unit '#{params[:units]}'. Must be one of #{valid_units.join(", ")}.")
    end
  end
end
