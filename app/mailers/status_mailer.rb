require "tzinfo"

class StatusMailer < ActionMailer::Base
  def default_email
    "agweather@cals.wisc.edu"
  end

  def status_recipients
    [default_email] << User.admin_emails
  end

  def status_mail(statuses)
    @statuses = statuses
    mail(
      to: status_recipients,
      from: default_email,
      subject: "Data import problem on #{ENV["AG_WEATHER_HOST"] || "unknown host"}"
    )
  end
end
