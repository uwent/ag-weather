module LocalDataMethods
  # compute daily values
  def create_data(start_date: earliest_date, end_date: latest_date, all_dates: false, overwrite: false)
    ActiveRecord::Base.logger.level = :info

    dates = all_dates ? (start_date.to_date..end_date.to_date).to_a : missing_dates(start_date:, end_date:)
    return Rails.logger.info "#{name} :: Everything's up to date, nothing to do!" if dates.empty?

    dates.each do |date|
      if data_class.find_by(date:) && !overwrite
        Rails.logger.info "#{name} :: Data already exists for #{date}, force with overwrite: true"
        import.succeed(date)
        next
      end
      Rails.logger.info "#{name} :: Calculating data for #{date}"
      create_data_for_date(date)
    rescue => e
      msg = "Failed to calculate data for #{date}: #{e.message}"
      Rails.logger.warn "#{name} :: #{msg}"
      import.fail(date, msg)
      next
    end

    ActiveRecord::Base.logger.level = Rails.configuration.log_level
  end
end
