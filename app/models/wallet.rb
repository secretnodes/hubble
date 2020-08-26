class Wallet < ApplicationRecord
  belongs_to :user
  belongs_to :chain, class_name: "Secret::Chain"

  enum wallet_type: [:ledger, :mathwallet, :keplr]

  validates :wallet_type, :chain_type, presence: true
  validates :public_address, uniqueness: true
  validates :default_wallet, uniqueness: { scope: :user_id }, if: :default_wallet?

  def constantize_chain_type
    chain_type.capitalize.constantize
  end
end
