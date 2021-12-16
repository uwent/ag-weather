class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :null_session

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
end
