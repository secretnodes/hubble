class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => Rails.application.credentials[Rails.env.to_sym][:two_factor_key]

  MASQ_TIMEOUT = 10.minutes

  has_many :alert_subscriptions

  has_many :watches, class_name: 'Common::Watch'

  has_many :wallets

  enum role: %i{ base foundation sudo }

  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, uniqueness: true, allow_blank: true

  default_scope -> { where.not( deleted: true ) }

  def verified?
    verification_token.nil?
  end

  def subscribed_to?( alertable )
    alert_subscriptions.where( alertable: alertable ).exists?
  end

  def update_for_request( ua:, ip: )
    self.last_seen_at = Time.now
    update_details ua: ua, ip: ip
    save
  end

  def update_for_login( ua:, ip: )
    self.last_login_at = Time.now
    self.last_seen_at = Time.now
    update_details ua: ua, ip: ip
    save
  end

  def update_for_signup( ua:, ip: )
    update_details ua: ua, ip: ip
    save
  end

  def generate_two_factor_secret_if_missing!
    return unless otp_secret.nil?
    update!(otp_secret: User.generate_otp_secret)
  end

  def enable_two_factor!
    update!(otp_required_for_login: true)
  end

  def disable_two_factor!
    update!(
        otp_required_for_login: false,
        otp_secret: nil)
  end

  def two_factor_qr_code_uri
    issuer = 'Puzzle Report'
    label = [issuer, email].join(':')

    otp_provisioning_uri(label, issuer: issuer)
  end

  private
  def update_details( ua:, ip: )
    if ua
      json_ua = JsonUserAgent.new( ua ).as_json.to_json
      self.user_agents = [ json_ua, *(user_agents||[]) ].uniq.slice(0, 5)
    end

    if ip
      self.ip_addresses = [ ip, *(ip_addresses||[]) ].uniq.slice(0, 5)
    end
  end
end
