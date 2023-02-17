class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :null_session

  rescue_from ActionController::ParameterMissing do |e|
    render json: {error: e.message}, status: :bad_request
  end

  def index
  end

  private

  def to_csv(data, headers = nil)
    CSV.generate do |csv|
      if headers
        headers.each { |h| csv << [h[0], h[1]] }
        csv << []
      end
      csv << data.first.keys
      data.each { |h| csv << h.values }
    rescue
    end
  end

  def default_date
    DataImport.latest_date
  end

  ## PARSE PARAMS ##

  def parse_number(s)
    (!/\D/.match?(s)) ? s.to_i : nil
  end

  def date
    Date.parse(params[:date])
  rescue
    default_date
  end

  def date_from_id
    Date.parse(params[:id])
  rescue
    default_date
  end

  def start_date(default = default_date.beginning_of_year)
    Date.parse(params[:start_date])
  rescue
    default
  end

  def end_date
    Date.parse(params[:end_date])
  rescue
    default_date
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

  def lat
    params[:lat]&.to_d&.round(1)
  end

  def long
    params[:long]&.to_d&.round(1)
  end

  def lat_range
    parse_coords(params[:lat_range], LandExtent.latitudes)
  end

  def long_range
    parse_coords(params[:long_range], LandExtent.longitudes)
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
