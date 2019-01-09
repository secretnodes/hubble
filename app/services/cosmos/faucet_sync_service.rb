class Cosmos::FaucetSyncService < Cosmos::SyncBase
  def sync_token_info!( faucet=nil )
    faucet ||= @chain.faucet
    return if faucet.nil?
    return if faucet.disabled?

    if faucet.address.nil?
      faucet.address = get_key( faucet.key_name )['address']
    end

    puts "Syncing token info for faucet #{faucet.id} (#{faucet.key_name} / #{faucet.address})..."
    info = get_account_info( faucet.address )

    if !info.nil?
      faucet.tokens = info['value']['coins']
      faucet.account_number = info['value']['account_number']
      faucet.current_sequence = info['value']['sequence']
      puts "\tInfo: #{info.inspect}\n\tUpdates: #{faucet.changes.inspect}\n" if ENV['DEBUG']
    else
      # no info yet, because the account has nothing
      puts "\tNo info was retrievable. No update."
    end

    faucet.save
  end
end
