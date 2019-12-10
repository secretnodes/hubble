class User < ApplicationRecord
  has_secure_password
  MASQ_TIMEOUT = 10.minutes

  has_many :alert_subscriptions

  has_many :watches, class_name: 'Common::Watch'

  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

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
