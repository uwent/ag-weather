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

    conditions = {
      date: start_date..end_date,
      latitude: lat,
      longitude: long
    }

    insols = Insolation.where(conditions)

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

    response = {status:, info:, data:}

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

  # GET: return grid of all values for date
  # params:
  #   date or end_date - defaults to most recent data
  #   start_date - optional, provides a sum across dates if given
  #   lat_range - optional, constrain latitudes i.e. '45,50'
  #   long_range - optional, constrain longitudes i.e. '-89,-85'

  def grid
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    end_date = date || end_date
    start_date = start_date(nil) || end_date
    days_requested = (start_date..end_date).count
    days_returned = 0
    query = {
      date: start_date..end_date,
      latitude: lat_range,
      longitude: long_range
    }
    data = Insolation.where(query)

    if data.exists?
      days_returned = data.where(latitude: lat_range.min, longitude: long_range.min).size
      data = data.grid_summarize.sum(:insolation)
      data.each { |k, v| data[k] = UnitConverter.mj_to_kwh(v) } if units == "KWh"
      status = "missing data" if days_returned < days_requested - 1
    else
      status = "no data"
    end

    values = data.values

    info = {
      status:,
      start_date:,
      end_date:,
      days_requested:,
      days_returned:,
      lat_range: [lat_range.min, lat_range.max],
      long_range: [long_range.min, long_range.max],
      grid_points: data.size,
      min_value: values.min,
      max_value: values.max,
      units: "Solar insolation (MJ/day)",
      compute_time: Time.current - start_time
    }

    response = {info:, data:}

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        csv_data = data.collect do |key, value|
          {latitude: key[0], longitude: key[1], value:}
        end
        headers = info unless params[:headers] == "false"
        filename = "insol data grid for #{@date}.csv"
        send_data(to_csv(csv_data, headers), filename:)
      end
    end
  end

  # GET: create map and return url to it

  def map
    start_time = Time.current

    @end_date = params[:date].present? ? date : end_date
    @start_date = start_date(nil)
    @start_date = nil if @start_date == @end_date
    @units = units
    @extent = params[:extent]
    puts @image_args = {
      start_date: @start_date,
      end_date: @end_date,
      units: @units,
      extent: @extent
    }.compact

    image_name, _ = Insolation.image_attr(**@image_args)
    image_filename = Insolation.image_path(image_name)
    image_url = Insolation.image_url(image_name)

    @status = "unable to create image, invalid query or no data"

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = Insolation.create_image(**@image_args)
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
          start_date: @start_date,
          end_date: @end_date,
          units: @units,
          compute_time: Time.current - start_time
        },
        map: @url
      }
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
    unit = params[:units]&.downcase || Insolation.valid_units[0]
    if Insolation.valid_units.include?(unit)
      unit
    else
      reject("Invalid unit '#{unit}'. Must be one of #{Insolation.valid_units.join(", ")}.")
    end
  end
end
