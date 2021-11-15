class StatusMailer < ActionMailer::Base
  default from: "agweather@cals.wisc.edu"

  def status_mail(statuses)
    @statuses = statuses
    mail to: "agweather@cals.wisc.edu", subject: "AgWeather status"
  end
end
