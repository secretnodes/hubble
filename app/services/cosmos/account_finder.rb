class Cosmos::AccountFinder

  def initialize( chain, objects, type )
    @type = type
    @chain = chain
    @objects = objects
  end

  def run
    case @type
    when :transactions then find_in_transactions
    else raise ArgumentError.new( "AccountFinder does not support #{@type}." )
    end
  end

  private

  def find_in_transactions
    @objects.each do |obj|
      obj['tx']['value']['msg'].map { |msg| msg['value'] }.flatten.map do |info|
        info.entries.map do |k, v|
          case k
          when 'validator_addr' then cosmos_val_oper1_to_cosmos1(v)
          when 'delegator_addr' then v
          when 'depositor' then v
          else
            # we don't know all the keys right now
            # so let's do a ham-fisted string check
            # to see if this is likely an account address
            if v.is_a?(String) && v.starts_with?( 'cosmos1' ) then v
            elsif v.is_a?(String) && v.starts_with?( 'cosmosvaloper1' ) then cosmos_val_oper1_to_cosmos1(v)
            else nil
            end
          end
        end
      end.flatten.compact.each do |address|
        @chain.accounts.find_or_create_by( address: address )
      end
    end
  end

  def cosmos_val_oper1_to_cosmos1( v )
    bytes = Bitcoin::Bech32.decode( v )[1]
    Bitcoin::Bech32.encode( 'cosmos', bytes )
  end
end
