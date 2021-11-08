class EvapotranspirationsController < ApplicationController
  
  # GET: returns ets for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today

  def index
    start_time = Time.current
    status = "OK"
    data = []

    ets = Evapotranspiration.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    if ets.size > 0
      data = ets.collect do |et|
        {
          date: et.date.to_s,
          value: et.potential_et.round(3)
        }
      end
    else
      status = "no data"
    end

    values = data.map { |day| day[:value] }
    days_requested = (end_date - start_date).to_i
    days_returned = values.size

    info = {
      lat: lat.to_f,
      long: long.to_f,
      start_date: start_date,
      end_date: end_date,
      days_requested: days_requested,
      days_returned: days_returned,
      min_value: values.min,
      max_value: values.max,
      units: "in/day",
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && days_requested != days_returned

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        filename = "et data for #{lat}, #{long}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: create map and return url to it
  def show
    date = begin
      params[:id] ? Date.parse(params[:id]) : default_et_date
    rescue
      default_et_date
    end

    image_name = Evapotranspiration.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      url = image_url
    else
      image_name = Evapotranspiration.create_image(date)
      url = image_name == "no_data.png" ? "/no_data.png" : image_url
    end

    if request.format.png?
      render html: "<img src=#{url} height=100%>".html_safe
    else
      render json: { map: url }
    end
  end

  # GET: return grid of all values for date
  # params:
  #   date

  def all_for_date
    start_time = Time.current
    status = "OK"
    info = {}
    data = []

    date = begin
      params[:date] ? Date.parse(params[:date]) : default_et_date
    rescue
      default_et_date
    end
    
    ets = Evapotranspiration.where(date: date).order(:latitude, :longitude)

    if ets.size > 0
      data = ets.collect do |et|
        {
          lat: et.latitude.to_f.round(1),
          long: et.longitude.to_f.round(1),
          value: et.potential_et.round(3)
        }
      end
      status = "OK"
    else
      status = "no data"
    end

    lats = data.map{ |d| d[:lat] }.uniq
    longs = data.map{ |d| d[:long] }.uniq
    values = data.map{ |d| d[:value] }

    info = {
      date: date,
      lat_range: [lats.min, lats.max],
      long_range: [longs.min, longs.max],
      grid_points: lats.count * longs.count,
      min_value: values.min,
      max_value: values.max,
      units: "Potential evapotranspiration (in/day)",
      compute_time: Time.current - start_time
    }

    response = {
      status: status,
      info: info,
      data: data
    }

    respond_to do |format|
      format.html { render json: response, content_type: "application/json; charset=utf-8"}
      format.json { render json: response }
      format.csv do
        headers = { status: status }.merge(info) unless params[:headers] == "false"
        filename = "et data grid for #{date.to_s}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
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

  # GET: valid params for api
  def info
    t = Evapotranspiration
    response = {
      date_range: [t.minimum(:date).to_s, t.maximum(:date).to_s],
      total_days: t.distinct.pluck(:date).size,
      lat_range: [t.minimum(:latitude), t.maximum(:latitude)],
      long_range: [t.minimum(:longitude), t.maximum(:longitude)],
      value_range: [t.minimum(:potential_et), t.maximum(:potential_et)],
      table_cols: t.column_names
    }
    render json: response
  end
end

private

def default_et_date
  Evapotranspiration.latest_date || Date.yesterday
end

def start_date
  params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
end

def end_date
  params[:end_date] ? Date.parse(params[:end_date]) : Date.current
end

def lat
  params[:lat].to_d.round(1)
end

def long
  params[:long].to_d.round(1)
end
