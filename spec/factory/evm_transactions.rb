FactoryBot.define do
    factory :evm_transaction do
      block_height { 1234567 }
      currency { 'MATIC' }
      fee { BigDecimal('0.01') }
      nonce { 1 }
      receiver_address { '0xreceiver' }
      sender_address { '0xsender' }
      txid { '0xtxid' }
      value { BigDecimal('10.0') }
    end
  end