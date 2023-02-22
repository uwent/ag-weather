module LocalDataMethods
  # check for and return missing dates
  def missing_dates(date = DataImport.latest_date)
    dates = date.beginning_of_year..date
    existing_dates = data_model.where(date: dates).distinct.pluck(:date)

    return nil if dates.count == existing_dates.size

    missing_dates = []
    dates.each do |d|
      missing_dates << d.to_s unless existing_dates.include?(d)
    end
    Rails.logger.info "#{name} :: Missing #{missing_dates.size} dates: #{missing_dates.join(", ")}."
    missing_dates
  end

  # compute daily values
  def create_data(date = DataImport.latest_date, force: false)
    date = date.to_date
    dates = force ? (date.beginning_of_year..date).map(&:to_s).to_a : missing_dates(date)

    if dates.count == 0
      Rails.logger.info "#{name} :: Everything's up to date, nothing to do!"
      return true
    else
      Rails.logger.info "#{name} :: Calculating data for #{dates.count} dates: #{dates.join(", ")}"
    end

    dates.each do |date|
      if data_model.on(date).exists? && !force
        Rails.logger.info "#{name} :: Data already exists for #{date}, overwrite with force: true"
        return true
      end
      Rails.logger.info "#{name} :: Calculating data for #{date}"
      create_data_for_date(date)
    end
  rescue => e
    Rails.logger.error "#{name} :: Failed to calculate data for #{dates.min} - #{dates.max}: #{e.message}"
    false
  end
end
