class Precip < ApplicationRecord
  attribute :latitude, :float
  attribute :longitude, :float
  
  extend GridMethods
  extend ImageMethods

  def self.default_col
    :precip
  end

  # stored in "mm"
  def self.valid_units
    ["in", "mm"]
  end

  def self.convert(value:, units:, **args)
    check_units(units)
    (units == "in") ? UnitConverter.mm_to_in(value) : value
  end

  def self.image_subdir
    "precip"
  end

  def self.image_title(date: nil, start_date: nil, end_date: nil, units: valid_units[0], **args)
    end_date ||= date
    raise ArgumentError.new log_prefix + "Must provide either 'date' or 'end_date'" unless end_date
    datestring = image_title_date(start_date:, end_date:)
    "Total precipitation (#{units}) for #{datestring}"
  end

  def self.stats(date)
    data = where(date:).pluck(:precip)

    if data.empty?
      puts "No precip data for #{date}"
    else
      pos_precips = data.find_all { |n| n > 0 }
      pts = data.size
      pts_precip = pos_precips.size
      precip_pct = (pts_precip.to_f / pts * 100).round(1)
      mean_precip = pos_precips.sum(0.0) / pts_precip
      max_precip = pos_precips.max

      puts "Precip stats for #{date}:"
      puts "Total points: #{data.size}"
      puts "Points with precip: #{pts_precip} (#{precip_pct}%)"
      puts "Mean precip: #{mean_precip.round(3)} mm"
      puts "Max precip: #{max_precip} mm"
    end
  end
end
