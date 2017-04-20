class PestForecastsController < ApplicationController

  private
  def start_date
    params[:start_date].blank? ? 7.days.ago.to_date : Date.parse(params[:start_date])
  end

  def end_date
    params[:end_date].blank? ? Date.current : Date.parse(params[:end_date])
  end

  def lat
    params[:latitude].to_f.round(1)
  end

  def long
    params[:longitude].to_f.round(1).abs
  end
end
