class StatusMailer < ActionMailer::Base

  def default_email
    "agweather@cals.wisc.edu"
  end

  def admin_emails
    User.where(admin: true).pluck(:email)
  rescue
    []
  end

  def status_recipients
    admin_emails << default_email
  end

  def status_mail(statuses)
    @statuses = statuses
    mail(
      to: status_recipients,
      from: default_email,
      subject: "AgWeather status"
    )
  end
end
