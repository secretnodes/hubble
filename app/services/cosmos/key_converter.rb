class Cosmos::KeyConverter
  class << self

    def addr_to_bech32( hex_addr )
      bytes = [hex_addr].pack('H*').bytes
      Bitcoin::Bech32.encode(
        'cosmosvaladdr',
        Bitcoin::Bech32.convert_bits(
          bytes,
          from_bits: 8, to_bits: 5, pad: true
        )
      )
    end

    def pubkey_to_bech32( base64_pubkey_value )
      bytes = [
        *["1624DE6420"].pack('H*').bytes,
        *Base64.decode64( base64_pubkey_value ).bytes
      ]

      Bitcoin::Bech32.encode(
        'cosmosvalpub',
        Bitcoin::Bech32.convert_bits(
          bytes,
          from_bits: 8, to_bits: 5, pad: true
        )
      )
    end

  end
end
