class Cosmos::SyncBase
  class CriticalError < StandardError; end

  BATCH_SIZE = 20

  def initialize( chain, request_timeout_ms=10_000 )
    @chain = chain
    @host = @chain.get_gaiad_host_or_default
    @rpc_port = @chain.get_rpc_port_or_default
    @lcd_port = @chain.get_lcd_port_or_default

    @rpc_curl = Curl::Easy.new
    # @rpc_curl.verbose = !Rails.env.production?
    @rpc_curl.timeout_ms = request_timeout_ms unless Rails.env.development?
    @rpc_curl.headers['Accept'] = 'application/json'
    @rpc_curl.headers['Content-Type'] = 'application/json'

    @lcd_curl = Curl::Easy.new
    # @lcd_curl.verbose = !Rails.env.production?
    @lcd_curl.timeout_ms = request_timeout_ms unless Rails.env.development?
    @lcd_curl.headers['Accept'] = 'application/json'
    @lcd_curl.headers['Content-Type'] = 'application/json'
    # temporary, until we figure out/decide how to handle certs
    @lcd_curl.ssl_verify_peer = false
    @lcd_curl.ssl_verify_host = 0

    begin
      ext_id = get_node_chain
    rescue
      puts "#{$!.message}"
    end

    if !ext_id
      chain.sync_failed!
      raise CriticalError.new("Unable to communicate with node!")
    end

    if @chain.ext_id.blank?
      @chain.update_attributes ext_id: ext_id
    end

    if ext_id != @chain.ext_id
      chain.sync_failed!
      raise CriticalError.new("Node is running on chain #{ext_id} and cannot sync #{@chain.ext_id}.")
    end
  end

  def get_status
    rpc_get( 'status' )
  end

  def get_block( height )
    rpc_get( 'block', height: height )
  end

  def get_blocks( first, last )
    rpc_get( 'blockchain', minHeight: first, maxHeight: last )
  end

  def get_commit( height )
    rpc_get( 'commit', height: height )
  end

  def get_validator_set( height )
    rpc_get( 'validators', height: height )
  end

  def get_transaction( hash )
    lcd_get( [ 'txs', hash ] )
  end

  def get_account_info(addr)
    lcd_get( [ 'accounts', addr ] )
  end

  def get_key(name)
    lcd_get( [ 'keys', name ] )
  end

  def get_keys
    r = lcd_get( 'keys' )
    return r if r.is_a? Array
    return []
  end

  def get_new_seed
    lcd_get( 'keys/seed' )
  end

  def create_key( name, password )
    seed = get_new_seed.strip
    lcd_post( 'keys', name: name, password: password, seed: seed )
    get_key( name )
    seed
  end

  def get_stake_info
    r = lcd_get( 'stake/validators' )
    r.is_a?( Array ) ? r : nil
  end

  def get_genesis
    rpc_get( 'genesis' )
  end

  def get_consensus_state
    rpc_get( 'dump_consensus_state' )
  end

  def get_node_chain
    result = get_status
    result['result']['node_info']['network']
  end

  def get_canonical_block_height
    get_status['result']['sync_info']['latest_block_height'].to_i - 1
  end

  def get_peer_count
    result = rpc_get( 'net_info' )
    result['result']['n_peers'].to_i
  end

  def get_governance
    result = rpc_get( 'genesis' )
    info = result['result']['genesis']['app_state']['gov']
    (info||{}).slice('deposit_params', 'voting_params', 'tally_params')
  end

  def get_proposals
    lcd_get( 'gov/proposals' )
  end

  def get_proposal_deposits( proposal_id )
    lcd_get( [ 'gov/proposals', proposal_id, 'deposits' ] )
  end

  def get_proposal_votes( proposal_id )
    lcd_get( [ 'gov/proposals', proposal_id, 'votes' ] )
  end

  def get_proposal_tally( proposal_id )
    lcd_get( [ 'gov/proposals', proposal_id, 'tally' ] )
  end

  private

  def rpc_get( path, params=nil )
    path = path.join('/') if path.is_a?(Array)
    path += "?#{params.to_query}" if params
    @rpc_curl.url = "http://#{@host}:#{@rpc_port}/#{path}"

    start_time = Time.now.utc.to_f
    Rails.logger.debug "COSMOS RPC GET: #{@rpc_curl.url}"
    @rpc_curl.http_get
    end_time = Time.now.utc.to_f
    Rails.logger.info "COSMOS RPC #{path} took #{end_time - start_time} seconds" unless Rails.env.production?

    json = @rpc_curl.body_str
    JSON.load( json )
  end

  def lcd_get( path, params=nil )
    path = path.join('/') if path.is_a?(Array)
    path += "?#{params.to_query}" if params
    @lcd_curl.url = "https://#{@host}:#{@lcd_port}/#{path}"

    start_time = Time.now.utc.to_f
    Rails.logger.debug "COSMOS LCD GET: #{@lcd_curl.url}"
    @lcd_curl.http_get
    end_time = Time.now.utc.to_f
    Rails.logger.info "COSMOS LCD #{path} took #{end_time - start_time} seconds" unless Rails.env.production?

    json = @lcd_curl.body_str
    JSON.load( json ) rescue json
  end

  def lcd_post( path, body )
    path = path.join('/') if path.is_a?(Array)
    @lcd_curl.url = "https://#{@host}:#{@lcd_port}/#{path}"
    json_payload = body.to_json

    start_time = Time.now.utc.to_f
    Rails.logger.debug "COSMOS LCD GET: #{@lcd_curl.url}"
    @lcd_curl.http_post json_payload
    end_time = Time.now.utc.to_f
    Rails.logger.info "COSMOS LCD #{path} took #{end_time - start_time} seconds" unless Rails.env.production?

    json = @lcd_curl.body_str
    JSON.load( json ) rescue json
  end
end
