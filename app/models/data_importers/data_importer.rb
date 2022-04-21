class DataImporter
  def self.elapsed(start_time)
    ActiveSupport::Duration.build((Time.now - start_time).round).inspect
  end
end
