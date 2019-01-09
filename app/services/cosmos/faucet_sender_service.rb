class Cosmos::FaucetSenderService < Cosmos::SyncBase

  def initialize( chain )
    super( chain, 30_000 ) # much longer timeout to make a transaction
  end

  def fund( transaction )
    faucet = @chain.faucet

    # we may need to update account number and sequence and stuff
    Cosmos::FaucetSyncService.new(@chain).sync_token_info!

    payload = {
      amount: [
        { denom: transaction.denomination, amount: transaction.amount.to_i.to_s }
      ],
      name: faucet.key_name,
      password: faucet.password,
      chain_id: @chain.ext_id,
      account_number: faucet.account_number,
      sequence: (faucet.current_sequence.to_i + 1).to_s,
      gas: 10_000_000.to_s # lol wat?
    }

    r = lcd_post( ['accounts', transaction.address, 'send'], payload )

    # sample
    # {"check_tx"=>
    #   {"log"=>"Msg 0: ",
    #    "gasUsed"=>"3388",
    #    "tags"=>
    #     [{"key"=>"c2VuZGVy",
    #       "value"=>
    #        "Y29zbW9zYWNjYWRkcjFtN3J0YWNxOXlnbmcyemYyeTR6M21lcjhoZHRhY2c0aHlzcG1yaA=="},
    #      {"key"=>"cmVjaXBpZW50",
    #       "value"=>
    #        "Y29zbW9zYWNjYWRkcjEzNG11d2w2YTBuOHN1YzVncnVqNmdoMmthNzR3a2g0a3FoOHZtNA=="}],
    #    "fee"=>{"key"=>""}},
    #  "deliver_tx"=>
    #   {"log"=>"Msg 0: ",
    #    "gasUsed"=>"3388",
    #    "tags"=>
    #     [{"key"=>"c2VuZGVy",
    #       "value"=>
    #        "Y29zbW9zYWNjYWRkcjFtN3J0YWNxOXlnbmcyemYyeTR6M21lcjhoZHRhY2c0aHlzcG1yaA=="},
    #      {"key"=>"cmVjaXBpZW50",
    #       "value"=>
    #        "Y29zbW9zYWNjYWRkcjEzNG11d2w2YTBuOHN1YzVncnVqNmdoMmthNzR3a2g0a3FoOHZtNA=="}],
    #    "fee"=>{}},
    #  "hash"=>"E619758EBD58356AFB166FE3DBE7B02AC4DD554B",
    #  "height"=>"13385"}

    puts "RESPONSE: #{r.inspect}" if ENV['DEBUG']

    if r.is_a?(Hash)
      # we got json back
      transaction.update_attributes(
        result_data: r,
        completed_at: Time.now
      )
    else
      # we got a string... failure? shrug
      transaction.update_attributes result_data: { error_string: r }
    end

    return transaction.completed?
  end

end
