class PestForecast < ApplicationRecord

  extend PestModels

  NO_MAX = 150

  def self.for_lat_long_date_range(lat, long, start_date, end_date)
    where(latitude: lat)
      .where(longitude: long)
      .where("date >= ? and date <= ?", start_date, end_date)
      .order(date: :desc)
  end

  # degree days in F
  def self.new_from_weather(weather)
    PestForecast.new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_late_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      dd_39p2_86: weather.degree_days(39.2, 86),    # 4 / 30 C
      dd_41_86: weather.degree_days(41, 86),        # 5 / 30 C
      dd_41_88: weather.degree_days(41, 88),        # 5 / 31 C
      dd_41_none: weather.degree_days(41, NO_MAX),  # 5 / none C
      dd_42p8_86: weather.degree_days(42.8, 86),    # 6 / 30 C
      dd_45_none: weather.degree_days(45, NO_MAX),  # 7.2 / none C
      dd_45_86: weather.degree_days(45, 86),        # 7.2 / 30 C
      dd_48_none: weather.degree_days(48, NO_MAX),  # 9 / none C
      dd_50_86: weather.degree_days(50, 86),        # 10 / 30 C
      dd_50_88: weather.degree_days(50, 88),        # 10 / 31.1 C
      dd_50_90: weather.degree_days(50, 90),        # 10 / 32.2 C
      dd_50_none: weather.degree_days(50, NO_MAX),  # 10 / none C
      dd_52_none: weather.degree_days(52, NO_MAX),  # 11.1 / none C
      dd_54_92: weather.degree_days(54, 92),        # 12.2 / 33.3 C
      dd_55_92: weather.degree_days(55, 92)         # 12.8 / 33.3 C
    )
  end

  def self.create_image(pest, start_date = Date.current.beginning_of_year, end_date = Date.current)
    raise ArgumentError.new("Pest not found!") if !PestForecast.column_names.include?(pest)

    Rails.logger.info "PestForecast :: Creating #{pest} image for #{start_date.to_s} - #{end_date.to_s}"

    forecasts = PestForecast.where(date: start_date..end_date)

    if forecasts.size > 0
      grid = LandGrid.new
      totals = forecasts.group(:latitude, :longitude)
      .order(:latitude, :longitude)
      .select(:latitude, :longitude, "sum(#{pest}) as total")

      totals.each do |pf|
        lat = pf.latitude
        long = pf.longitude
        grid[lat, long] = pf.total
      end

      title = "Totals map for #{pest.gsub("_", "-")} for #{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
      ImageCreator.create_image(grid, title, image_name(pest, start_date, end_date))
    else
      Rails.logger.warn "PestForecast :: Failed to create image for #{pest}: No data"
      return "no_data.png"
    end
  end

  def self.image_name(pest, start_date, end_date)
    "#{pest}_grid_#{start_date.to_s(:number)}_#{end_date.to_s(:number)}.png"
  end

  def self.latest_date
    PestForecast.maximum(:date)
  end

  def self.earliest_date
    PestForecast.minimum(:date)
  end

end
