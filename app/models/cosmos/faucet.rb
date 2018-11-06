class Cosmos::Faucet < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  has_many :transactions, as: :faucetlike, class_name: 'Cosmos::FaucetTransaction', dependent: :delete_all

  attribute :password
  attr_encrypted :password, key: proc { Rails.application.secrets.faucet_key_base }

  scope :enabled, -> { where( disabled: false ) }

  AMOUNT = 2

  def ready?
    !(tokens.nil? || account_number.nil? || current_sequence.nil?)
  end

  def can_fund?( user:, address:, ip: )
    recent = latest_funding( user: user, address: address, ip: ip )
    return !recent || recent.created_at < delay.seconds.ago
  end

  def latest_funding( user:, address:, ip: )
    q = [
      ('user_id' if user),
      ('address' if address),
      'ip'
    ].compact
     .map { |field| "#{field} = ?" }
     .join( ' OR ' )

    bindings = [ user.try(:id), address, ip ].compact

    transactions.find_by( q, *bindings )
  end

  def tokens_by_denomination
    tokens.each_with_object({}) { |t, o| o[t['denom']] = t['amount'] }
  end
end
