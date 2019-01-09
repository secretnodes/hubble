class Cosmos::Block < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  default_scope { order('height DESC') }

  validates :height, presence: true, uniqueness: { scope: :chain }
  validates :id_hash, presence: true, uniqueness: { scope: :chain }
  validates :timestamp, presence: true

  def to_param; height.to_s; end

  def previous_block
    chain.blocks.find_by( height: height - 1 )
  end
  def next_block
    chain.blocks.find_by( height: height + 1 )
  end

  def proposer
    return nil if proposer_address.blank?
    chain.validators.find_by( address: proposer_address )
  end

  def validator_in_set?( validator )
    validator_set.keys.include?(validator.address)
  end

  def transaction_objects
    return [] if transactions.nil?
    begin
      transactions.map { |hash| Cosmos::TransactionDecorator.new(chain, hash) }
    rescue
      nil
    end
  end

  class << self
    def assemble_from_cache( chain, height )
      Rails.cache.fetch( ['block', chain.id.to_s, height.to_s].join('-') ) do
        assemble( chain, height )
      end
    end

    def assemble( chain, height, block_meta=nil, raw_commit=nil, raw_validator_set=nil )
      if block_meta.nil?
        # we're building this block from scratch with no data
        begin
          syncer = Cosmos::SyncBase.new( chain, 250 )
          raw_block = syncer.get_block( height )['result']
          block_txs = raw_block['block']['data']['txs']
          block_meta = raw_block['block_meta']
        rescue
          raise Cosmos::SyncBase::CriticalError.new("Unable to retrieve or invalid object for block #{height}.")
        end

        raw_commit = syncer.get_commit( height )
        raw_validator_set = syncer.get_validator_set( height )
      else
        # we don't need to look up the whole block unless
        # there are transactions in the block
        begin
          if block_meta['header']['num_txs'].to_i > 0
            syncer = Cosmos::SyncBase.new( chain, 250 )
            block_txs = syncer.get_block( height )['result']['block']['data']['txs']
          end
        rescue
          raise Cosmos::SyncBase::CriticalError.new("Unable to retrieve or invalid transaction info for block #{height}.")
        end
      end

      begin
        precommitters = if raw_commit['result'].has_key?('signed_header')
          # cosmos 0.25.0+
          raw_commit['result']['signed_header']['commit']['precommits']
        else
          # older cosmos (8001 and before)
          raw_commit['result']['SignedHeader']['commit']['precommits']
        end

        addresses = precommitters.map { |pc| pc['validator_address'] rescue nil }.compact
      rescue
        raise Cosmos::SyncBase::CriticalError.new("Invalid validator/precommitter list for block #{height}.")
      end

      begin
        validator_set = raw_validator_set['result']['validators'].each_with_object({}) { |o, h| h[o['address']] = o['voting_power'].to_i }.reject { |k, v| k.blank? }
      rescue
        raise Cosmos::SyncBase::CriticalError.new("Invalid validator voting set information for block #{height}.")
      end

      begin
        transactions = block_txs.try(:map) { |data| Digest::SHA256.hexdigest(Base64.decode64(data)) }
      rescue
        raise Cosmos::SyncBase::CriticalError.new("Unable to decode or invalid transaction data for block #{height}.")
      end

      obj = {
        chain_id: chain.id,
        height: height,
        id_hash: block_meta['block_id']['hash'],
        timestamp: block_meta['header']['time'].to_datetime,
        proposer_address: block_meta['header']['proposer_address'],
        precommitters: addresses,
        validator_set: validator_set,
        transactions: transactions
      }

      if (t = self.new( obj )).invalid?
        puts "Invalid block at height: #{height}\n#{obj.inspect}\nError description: #{t.errors.full_messages.join(", ")}\n\n"
        raise Cosmos::SyncBase::CriticalError.new("Invalid block at height #{height}.")
      end

      obj
    end

    def stub_from_cache( *args )
      self.new( assemble_from_cache( *args ) )
    end

    def stub( *args )
      self.new( assemble( *args ) )
    end
  end
end
