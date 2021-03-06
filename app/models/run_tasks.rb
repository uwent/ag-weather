class RunTasks

  def self.all
    WeatherImporter.fetch
    InsolationImporter.fetch
    EvapotranspirationImporter.create_et_data
    PestForecastImporter.create_forecast_data
    Evapotranspiration.create_and_static_link_image
  end

end
