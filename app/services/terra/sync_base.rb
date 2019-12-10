class Terra::SyncBase < Common::SyncBase
  def get_transactions( params=nil )
    params ||= {}
    params['limit'] = 1000
    r = lcd_get( 'txs', params )
    if r.is_a?(Hash)
      r['txs']
    else
      []
    end
  end

  def get_community_pool
    nil
  end
end
