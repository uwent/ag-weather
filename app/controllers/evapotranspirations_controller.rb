class EvapotranspirationsController < ApplicationController
  # GET: returns ets for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today
  #   units - optional, either 'in' (default) or 'mm'

  def index
    params.require([:lat, :long])

    start_time = Time.current
    status = "OK"
    data = []

    conditions = {date: start_date..end_date, latitude: lat, longitude: long}

    # have to calculate from weather & insol
    if params[:method] == "adjusted"
      weather = {}
      insols = {}
      WeatherDatum.where(conditions).each { |w| weather[w.date] = w }
      Insolation.where(conditions).each { |i| insols[i.date] = i }

      if weather.empty? && insols.empty?
        status = "no data"
      else
        data = []
        cumulative_value = 0
        start_date.upto(end_date) do |date|
          if weather[date].nil? || insols[date].nil?
            value = 0
          else
            t = weather[date].avg_temp
            vp = weather[date].vapor_pressure
            i = insols[date].insolation
            d = date.yday
            l = lat

            # classic = EvapotranspirationCalculator.et(t, vp, i, d, l)
            value = EvapotranspirationCalculator.et_adj(t, vp, i, d, l)
            # Rails.logger.debug "> classic: #{reg}\n> adjusted: #{adj}\n> diff: #{(100 * (adj - reg) / reg).round(1)}%"
          end
          value = UnitConverter.in_to_mm(value) if units == "mm"
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
          value = UnitConverter.in_to_mm(value) if units == "mm"
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
      cumulative_value: values.sum,
      units: "#{units}/day",
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && days_requested != days_returned

    response = {status:, info:, data:}

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8" }
      format.json { render json: response }
      format.csv do
        headers = info unless params[:headers] == "false"
        filename = "et data for #{lat}, #{long}.csv"
        send_data(to_csv(response[:data], headers), filename:)
      end
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date - default most recent date

  def grid
    start_time = Time.current
    status = "OK"
    info = {}
    data = {}

    end_date = date || end_date
    start_date = start_date(nil) || end_date
    days_requested = (start_date..end_date).count
    days_returned = 0
    query = {
      date: start_date..end_date,
      latitude: lat_range,
      longitude: long_range
    }
    data = Evapotranspiration.where(query)

    if data.exists?
      days_returned = data.where(latitude: lat_range.min, longitude: long_range.min).size
      data = data.grid_summarize.sum(:potential_et)
      if units == "mm"
        data.each { |k, v| data[k] = UnitConverter.in_to_mm(v) }
      end
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
      units: "Potential evapotranspiration (in/day)",
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
        filename = "et data grid for #{@date}.csv"
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
    @image_args = {
      start_date: @start_date,
      end_date: @end_date,
      units: @units,
      extent: @extent
    }.compact

    image_name, _ = Evapotranspiration.image_attr(**@image_args)
    image_filename = Evapotranspiration.image_path(image_name)
    image_url = Evapotranspiration.image_url(image_name)

    @status = "unable to create image, invalid query or no data"

    if File.exist?(image_filename)
      @url = image_url
      @status = "already exists"
    else
      image_name = Evapotranspiration.create_image(**@image_args)
      if image_name
        @url = image_url
        @status = "image created"
      end
    end

    if request.format.png?
      render html: @url ? "<img src=#{@url} height=100%>".html_safe : "Unable to create image, invalid query or no data."
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

  # GET: calculate et with arguments

  # def calculate_et
  #   render json: {
  #     inputs: params,
  #     value: Evapotranspiration.new.potential_et
  #   }
  # end

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
    unit = params[:units]&.downcase || Evapotranspiration.valid_units[0]
    if Evapotranspiration.valid_units.include?(unit)
      unit
    else
      reject("Invalid unit '#{unit}'. Must be one of #{Evapotranspiration.valid_units.join(", ")}.")
    end
  end
end
