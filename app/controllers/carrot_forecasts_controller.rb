class CarrotForecastsController < PestForecastsController

  def index
    render json: PestForecast.carrot_foliar_severity_for(start_date, end_date)
  end

  def info
    dsvs = PestForecast.for_lat_long_date_range(lat, long, start_date, end_date)
      .map { |d| [d.date, d.carrot_foliar_dsv] }.to_h
    dsvs.default = 0

    weather = WeatherDatum.where(latitude: lat, longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date).collect do |w|
      {
        date: w.date,
        dsv: dsvs[w.date],
        avg_temperature: w.avg_temperature.round(1),
        hours_over: w.hours_rh_over_85
      }
    end

    render json: weather
  end
end
