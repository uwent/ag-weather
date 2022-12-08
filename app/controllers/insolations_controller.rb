class InsolationsController < ApplicationController
  # GET: returns insols for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default yesterday

  def index
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    data = []

    insols = Insolation.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    if insols.empty?
      status = "no data"
    else
      data = insols.collect do |insol|
        {
          date: insol.date.to_s,
          value: insol.insolation.round(3)
        }
      end
    end

    values = data.map { |day| day[:value] }

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date:,
      end_date:,
      days_requested: (start_date..end_date).count,
      days_returned: values.count,
      min_value: values.min,
      max_value: values.max,
      units: "MJ/day/m^2",
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && info[:days_requested] != info[:days_returned]

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
        filename = "insol data for #{lat}, #{long}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: create map and return url to it

  def show
    start_time = Time.current

    @date = [date_from_id, default_date].min
    if params[:start_date].present?
      @start_date = [[start_date, earliest_date].max, @date].min
      @start_date = nil if @start_date == @date
    end
    @units = units

    image_name = Insolation.image_name(@date, @start_date, @units)
    image_filename = File.join(ImageCreator.file_dir, image_name)

    if File.exist?(image_filename)
      url = File.join(ImageCreator.url_path, image_name)
    else
      image_name = Insolation.create_image(@date, start_date: @start_date, units: @units)
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
  #   date - defaults to most recent data

  def all_for_date
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    @date = date

    insols = Insolation.where(date: @date).order(:latitude, :longitude)

    if insols.empty?
      status = "no data"
    else
      data = insols.collect do |insol|
        {
          lat: insol.latitude.round(1),
          long: insol.longitude.round(1),
          value: insol.insolation.round(3)
        }
      end
    end

    lats = data.map { |d| d[:lat] }.uniq
    longs = data.map { |d| d[:long] }.uniq
    values = data.map { |d| d[:value] }

    info = {
      date: @date,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      points: lats.count * longs.count,
      min_value: values.min,
      max_value: values.max,
      units: "Solar insolation (MJ/day)",
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
        filename = "insol data grid for #{@date}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: Returns info about insolations db

  def info
    start_time = Time.current
    t = Insolation
    min_date = t.minimum(:date) || 0
    max_date = t.maximum(:date) || 0
    all_dates = (min_date..max_date).to_a
    actual_dates = t.distinct.pluck(:date).to_a
    response = {
      table_cols: t.column_names,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      value_range: [t.minimum(:insolation), t.maximum(:insolation)],
      date_range: [min_date.to_s, max_date.to_s],
      expected_days: all_dates.size,
      actual_days: actual_dates.size,
      compute_time: Time.current - start_time
    }
    render json: response
  end

  private

  def earliest_date
    Insolation.earliest_date || Date.current.beginning_of_year
  end

  def units
    valid_units = Insolation::UNITS
    if valid_units.include?(params[:units])
      params[:units]
    elsif !params[:units].present?
      valid_units.first
    else
      raise ActionController::BadRequest.new("Invalid unit '#{params[:units]}'. Must be one of #{valid_units.join(", ")}.")
    end
  end
end
