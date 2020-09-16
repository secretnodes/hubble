class Administrator < ApplicationRecord
  has_secure_password validations: false

  validates :password_digest, presence: true, if: -> { one_time_setup_token.nil? }

  def is_set_up?
    one_time_setup_token.blank? && !password_digest.blank? && otp_secret_key?
  end
end
