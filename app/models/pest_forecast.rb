class PestForecast < ApplicationRecord
  extend PestModels
  extend GridMethods
  extend ImageMethods

  def self.new_from_weather(weather)
    new(
      date: weather.date,
      latitude: weather.latitude,
      longitude: weather.longitude,
      potato_blight_dsv: compute_late_blight_dsv(weather),
      potato_p_days: compute_potato_p_days(weather),
      carrot_foliar_dsv: compute_carrot_foliar_dsv(weather),
      cercospora_div: compute_cercospora_div(weather),
      botcast_dsi: compute_botcast_dsi(weather)
    )
  end

  def self.col_names
    {
      potato_blight_dsv: "Late blight DSV",
      potato_p_days: "Early blight P-Day",
      carrot_foliar_dsv: "Carrot foliar disease DSV",
      cercospora_div: "Cercospora leaf spot DSV",
      botcast_dsi: "Botrytis botcast DSI"
    }.freeze
  end

  def self.default_col
    :potato_blight_dsv
  end

  def self.default_scale(**args)
    [0, 4]
  end

  def self.image_subdir
    "pest_models"
  end

  def self.image_name_prefix(col:, **args)
    str = col_names[col]
    str&.downcase&.tr(" ", "-")
  end

  def self.image_title(col:, date: nil, start_date: nil, end_date: nil, **args)
    end_date ||= date
    raise ArgumentError.new log_prefix + "Must provide either 'date' or 'end_date'" unless end_date

    pest_name = col_names[col] || "DSV"
    datestring = image_title_date(start_date:, end_date:)
    if start_date.nil?
    end
    "#{pest_name} totals for #{datestring}"
  end
end
