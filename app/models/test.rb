class Test
  def self.date
    1.week.ago
  end

  def self.models
    [Insolation, Precip, Evapotranspiration]
  end

  def self.extents
    [nil, "wi"]
  end

  def self.test_images
    models.each do |model|
      extents.each do |extent|
        Rails.logger.debug ">>> #{model} :: #{extent} <<<"
        model.create_image(date:, extent:)
        model.create_cumulative_image(extent:)
      end
    end
  end
end
