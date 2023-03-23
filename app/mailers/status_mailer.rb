require "tzinfo"

class StatusMailer < ActionMailer::Base
  def host_name
    ENV["AG_WEATHER_HOST"]&.gsub("https://", "") || "unknown host"
  end

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
      subject: "Data import problem on #{host_name}"
    )
  end
end
