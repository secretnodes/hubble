namespace :faucet do
  namespace :cosmos do

    task send: :environment do
      puts "\nStarting task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Faucet.enabled.find_each do |faucet|
        next if faucet.chain.disabled?
        TaskLock.with_lock!( :faucet, faucet.chain.id ) do
          pending = faucet.transactions.incomplete.fifo
          sender = Cosmos::FaucetSenderService.new( faucet.chain )

          pending.each do |tr|
            print "Faucet funding #{tr.address} as per #{tr.id}... "
            ok = sender.fund( tr )
            puts ok ? 'OK' : 'FAIL'
            puts if ENV['DEBUG']
          end

          begin
            fss = Cosmos::FaucetSyncService.new(faucet.chain)
            fss.sync_token_info!
          rescue
            nil
          end
        end
      end
      puts "Completed task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

  end
end
