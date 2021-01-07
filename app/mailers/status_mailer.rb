class StatusMailer < ActionMailer::Base
  default from: "cals-it-admin@cals.wisc.edu"

  def daily_mail(statuses)
    @statuses = statuses
    mail to: 'jcpanuska@wisc.edu, gevens@wisc.edu', subject: "AG Weather Status"
  end
end
