class InsolationsController < ApplicationController

  # GET: returns insols for lat, long, date range
  # params:
  #   lat (required)
  #   long (required)
  #   start_date - default 1st of year
  #   end_date - default today

  def index
    start_time = Time.current
    status = "OK"
    data = []

    insols = Insolation.where(latitude: lat, longitude: long)
      .where(date: start_date..end_date)
      .order(:date)

    if insols.size > 0
      data = insols.collect do |insol|
        {
          date: insol.date.to_s,
          value: insol.insolation.round(3)
        }
      end
    else
      status = "no data"
    end

    values = data.map{ |day| day[:value] }

    info = {
      lat: lat,
      long: long,
      start_date: start_date,
      end_date: end_date,
      days_requested: (end_date - start_date).to_i,
      days_returned: values.count,
      min_value: values.min,
      max_value: values.max,
      units: "MJ/day/m^2",
      compute_time: Time.current - start_time
    }

    status = "missing days" if status == "OK" && info[:days_requested] != info[:days_returned]

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
        filename = "insol data for #{lat}, #{long}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: create map and return url to it
  def show
    date = begin
      params[:id] ? Date.parse(params[:id]) : default_insol_date
    rescue
      default_insol_date
    end

    image_name = Insolation.image_name(date)
    image_filename = File.join(ImageCreator.file_path, image_name)
    image_url = File.join(ImageCreator.url_path, image_name)

    if File.exists?(image_filename)
      url = image_url
    else
      image_name = Insolation.create_image(date)
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
      params[:date] ? Date.parse(params[:date]) : default_insol_date
    rescue
      default_insol_date
    end

    insols = Insolation.where(date: date).order(:latitude, :longitude)

    if insols.size > 0
      data = insols.collect do |insol|
        {
          lat: insol.latitude.round(1),
          long: insol.longitude.round(1),
          value: insol.insolation.round(3)
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
      points: lats.count * longs.count,
      min_value: values.min,
      max_value: values.max,
      units: "Solar insolation (MJ/day)",
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
        filename = "insol data grid for #{date.to_s}.csv"
        send_data helpers.to_csv(response[:data], headers), filename: filename
      end
    end
  end

  # GET: valid params for api
  def info
    i = Insolation
    render json: {
      date_range: [i.minimum(:date).to_s, i.maximum(:date).to_s],
      total_days: i.distinct.pluck(:date).size,
      lat_range: [i.minimum(:latitude), i.maximum(:latitude)],
      long_range: [i.minimum(:longitude), i.maximum(:longitude)],
      value_range: [i.minimum(:insolation), i.maximum(:insolation)]
    }
  end
end

private

def default_insol_date
  Insolation.latest_date || Date.yesterday
end

def start_date
  params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_year
end

def end_date
  params[:end_date] ? Date.parse(params[:end_date]) : Date.current
end

def lat
  params[:lat]
end

def long
  params[:long]
end
