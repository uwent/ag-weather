class Precip < ApplicationRecord
  extend GridMethods
  extend ImageMethods

  def self.default_col
    :precip
  end

  # stored in "mm"
  def self.valid_units
    ["in", "mm"]
  end

  def self.convert(value, units)
    (units == "in") ? UnitConverter.mm_to_in(value) : value
  end

  def self.image_subdir
    "precip"
  end

  def self.image_title(
    date: nil,
    start_date: nil,
    end_date: nil,
    units: valid_units[0],
    **args)

    end_date ||= date
    raise ArgumentError.new log_prefix + "Must provide either 'date' or 'end_date'" unless end_date

    if start_date
      fmt = (start_date.year != end_date.year) ? "%b %-d, %Y" : "%b %-d"
      "Total cumulative precip (#{units}) for #{start_date.strftime(fmt)} - #{end_date.strftime("%b %-d, %Y")}"
    else
      "Total daily precip (#{units}) for #{end_date.strftime("%b %-d, %Y")}"
    end
  end

  def self.stats(date)
    data = where(date:).pluck(:precip)

    unless data.empty?
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
    else
      puts "No precip data for #{date}"
    end
  end
end
