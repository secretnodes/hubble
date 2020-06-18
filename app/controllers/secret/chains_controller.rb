class Secret::ChainsController < Common::ChainsController
  def broadcast
    tx = { tx: params[:payload] }

    if @chain.sdk_gte?( '0.34.0' )
      tx[:mode] = 'sync'
    else
      tx[:return] = 'sync'
    end

    r = @chain.syncer(5000).broadcast_tx( tx )
    ok = !r.has_key?('code') && !r.has_key?('error')
    Rails.logger.error "\n\nBROADCAST RESULT: #{r.inspect}\n\n"
    render json: { ok: ok }.merge(r)
  end
end
