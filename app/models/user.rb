class User < ApplicationRecord

  def self.admin
    where(admin: true)
  end

end