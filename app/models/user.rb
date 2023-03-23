class User < ApplicationRecord
  def self.admin
    where(admin: true)
  end

  def self.admin_emails
    admin.pluck(:email)
  end
end
