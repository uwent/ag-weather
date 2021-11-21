namespace :calc do
  desc "Calculates frost and freeze for PestForecasts from WeatherDatum"

  task frost: :environment do
    start_time = Time.current

    puts "Getting frost data"
    frosts = {}
    WeatherDatum.select(:date, :latitude, :longitude)
    .where("min_temperature < ?", 0.0)
    .each do |w|
      frosts["#{w.date.to_s}_#{w.latitude}_#{w.longitude}"] = true
    end

    puts "Getting freeze data"
    freezes = {}
    WeatherDatum.select(:date, :latitude, :longitude)
    .where("min_temperature < ?", -2.22)
    .each do |w|
      freezes["#{w.date.to_s}_#{w.latitude}_#{w.longitude}"] = true
    end

    puts "Matching frosts and freezes to ids"
    frost_ids = []
    freeze_ids = []
    PestForecast.all.each do |pf|
      key = "#{pf.date.to_s}_#{pf.latitude}_#{pf.longitude}"
      frost_ids << pf.id if frosts[key]
      freeze_ids << pf.id if freezes[key]
    end

    puts "Saving frost to PestForecasts"
    frost_ids = frost_ids.sort
    PestForecast.where(id: frost_ids).update_all(frost: true)

    puts "Saving freeze to PestForecasts"
    freeze_ids = freeze_ids.sort
    PestForecast.where(id: freeze_ids).update_all(freeze: true)

    puts "Completed in #{(Time.current - start_time).round(1)} seconds"
  rescue => e
    puts "Failed to populate frost and freeze: #{e.message}"
  end
end
