class StatusMailer < ActionMailer::Base
  default from: "agweather@cals.wisc.edu"

  def daily_mail(statuses)
    Rails.logger.info "StatusMailer :: Sending status email"
    @statuses = statuses
    mail to: "agweather@cals.wisc.edu", subject: "AgWeather status (#{Rails.env})"
    User.admin.each do |user|
      mail to: user.email, subject: "AgWeather status (#{Rails.env})"
    end
  end
end
