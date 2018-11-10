class Cosmos::SyncBase
  BATCH_SIZE = 20

  def initialize( chain, request_timeout_ms=10_000 )
    @chain = chain
    @host = @chain.get_gaiad_host_or_default
    @rpc_port = @chain.get_rpc_port_or_default
    @lcd_port = @chain.get_lcd_port_or_default

    @rpc_curl = Curl::Easy.new
    # @rpc_curl.verbose = !Rails.env.production?
    @rpc_curl.timeout_ms = request_timeout_ms# unless Rails.env.development?
    @rpc_curl.headers['Accept'] = 'application/json'
    @rpc_curl.headers['Content-Type'] = 'application/json'

    @lcd_curl = Curl::Easy.new
    # @lcd_curl.verbose = !Rails.env.production?
    @lcd_curl.timeout_ms = request_timeout_ms# unless Rails.env.development?
    @lcd_curl.headers['Accept'] = 'application/json'
    @lcd_curl.headers['Content-Type'] = 'application/json'
    # temporary, until we figure out/decide how to handle certs
    @lcd_curl.ssl_verify_peer = false
    @lcd_curl.ssl_verify_host = 0

    begin
      chain_slug = get_node_chain
    rescue
      puts "#{$!.message}"
    end

    if !chain_slug
      chain.sync_failed!
      raise "Unable to communicate with node -- #{@host}"
    end
    if chain_slug != @chain.slug
      chain.sync_failed!
      raise "Node #{@host} is running on chain #{chain_slug} and cannot sync #{@chain.slug}."
    end
  end

  def get_status
    rpc_get('status')
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

  def get_account_info( addr )
    lcd_get( ['accounts', addr] )
  end

  def get_key( name )
    lcd_get( ['keys', name] )
  end

  def get_keys
    lcd_get( 'keys' )
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
    lcd_get( 'stake/validators' )
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
    JSON.load(json)
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
    JSON.load(json) rescue json
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
    JSON.load(json) rescue json
  end
end
