class StatusMailer < ActionMailer::Base
  default from: "agweather@cals.wisc.edu"

  def daily_mail(statuses)
    @statuses = statuses
    User.admin.each do |user|
      mail to: user.email, subject: "AgWeather #{Rails.env} status"
    end
  end
end
