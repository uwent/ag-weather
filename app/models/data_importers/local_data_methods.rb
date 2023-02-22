module LocalDataMethods

  # compute daily values
  def create_data(start_date: earliest_date, end_date: latest_date, all_dates: false, overwrite: false)
    ActiveRecord::Base.logger.level = :info
    dates = if all_dates
      (start_date.to_date..end_date.to_date).to_a
    else
      missing_dates(start_date:, end_date:)
    end

    if dates.count == 0
      Rails.logger.info "#{name} :: Everything's up to date, nothing to do!"
      return true
    end

    dates.each do |date|
      begin
        if data_model.where(date:).exists? && !overwrite
          Rails.logger.info "#{name} :: Data already exists for #{date}, force with overwrite: true"
          import.succeed(date)
          next
        end
        Rails.logger.info "#{name} :: Calculating data for #{date}"
        create_data_for_date(date)
        import.succeed(date)
        true
      rescue => e
        msg = "Failed to calculate data for #{date}: #{e.message}"
        Rails.logger.warn "#{name} :: #{msg}"
        import.fail(date, msg)
        false
      end
    end
    ActiveRecord::Base.logger.level = Rails.configuration.log_level
  end
end
