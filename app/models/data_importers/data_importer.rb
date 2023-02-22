class DataImporter

  def self.latest_date
    DataImport.latest_date
  end

  def self.earliest_date
    DataImport.earliest_date
  end

  def self.elapsed(start_time)
    ActiveSupport::Duration.build((Time.now - start_time).round).inspect
  end

  # check for and return missing dates
  def self.missing_dates(start_date:, end_date: latest_date)
    dates = start_date.to_date..end_date.to_date
    existing_dates = data_model.where(date: dates).distinct.pluck(:date)
    missing_dates = []
    dates.each do |date|
      missing_dates << date unless existing_dates.include?(date)
    end
    if !missing_dates.empty?
      Rails.logger.info "#{name} :: Missing #{missing_dates.size} dates: #{missing_dates.join(", ")}."
    end
    missing_dates
  end
end
