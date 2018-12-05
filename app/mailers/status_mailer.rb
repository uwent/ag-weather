class StatusMailer < ActionMailer::Base
  default from: "noreply@cals.wisc.edu"

  def daily_mail(statuses)
    @statuses = statuses
    #    mail to: 'jcpanuska@wisc.edu, aballman@gmail.com', subject: "AG Weather Status"
    mail to: 'aballman@gmail.com', subject: "AG Weather Status"
  end
end
