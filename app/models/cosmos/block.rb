class Cosmos::Block < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  default_scope { order('height DESC') }

  def to_param; height.to_s; end

  def validator_in_set?( validator )
    validator_set.keys.include?(validator.address)
  end

  class << self
    def assemble( chain, height, raw_block=nil, raw_commit=nil, raw_validator_set=nil )
      if raw_block.nil?
        syncer = Cosmos::SyncBase.new( chain, 250 )
        raw_block = syncer.get_block( height )['result']['block_meta']
        raw_commit = syncer.get_commit( height )
        raw_validator_set = syncer.get_validator_set( height )
      end

      precommitters = if raw_commit['result'].has_key?('signed_header')
        # cosmos 0.25.0+
        raw_commit['result']['signed_header']['commit']['precommits']
      else
        # older cosmos (8001 and before)
        raw_commit['result']['SignedHeader']['commit']['precommits']
      end

      addresses = precommitters.map { |pc| pc['validator_address'] rescue nil }.compact
      validator_set = raw_validator_set['result']['validators'].each_with_object({}) { |o, h| h[o['address']] = o['voting_power'].to_i }

      obj = {
        chain_id: chain.id,
        height: height,
        id_hash: raw_block['block_id']['hash'],
        timestamp: raw_block['header']['time'].to_datetime,
        precommitters: addresses,
        validator_set: validator_set
      }
    end

    def stub( *args )
      self.new( assemble( *args ) )
    end
  end
end
