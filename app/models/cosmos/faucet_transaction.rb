class Cosmos::FaucetTransaction < ApplicationRecord
  belongs_to :faucet, class_name: 'Cosmos::Faucet'
  belongs_to :user, required: false

  validate :valid_destination_address
  validate :valid_denomination

  default_scope { order('created_at DESC') }

  scope :incomplete, -> { where( completed_at: nil, result_data: nil ) }
  scope :fifo, -> { reorder('created_at ASC') }

  def completed?
    !completed_at.nil?
  end

  def failed?
    !completed? && !result_data.nil?
  end

  def height
    result_data['height'].to_i
  end

  private

  def valid_destination_address
    if address.nil?
      errors.add(:address, 'must be specified')
    else
      if address !~ /^cosmosaccaddr1.+/
        errors.add(:address, 'must be in Cosmos bech32 format')
      end
    end
  end

  def valid_denomination
    if !faucet.tokens.map { |t| t['denom'] }.include?( denomination )
      errors.add(:denomination, 'is not a valid selection')
    end
  end
end
