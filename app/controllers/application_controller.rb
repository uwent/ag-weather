class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :null_session

  def index
  end

  def default_date
    DataImport.latest_date
  end
  
  def date_from_id
    Date.parse(params[:id])
  rescue
    default_date
  end
  
  def start_date
    Date.parse(params[:start_date])
  rescue
    default_date.beginning_of_year
  end
  
  def end_date
    Date.parse(params[:end_date])
  rescue
    default_date
  end
  
  def lat
    params[:lat].to_d.round(1)
  end
  
  def long
    params[:long].to_d.round(1)
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
end
