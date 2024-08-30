class EvmTransaction < ApplicationRecord
    # バリデーションの追加
    validates :txid, presence: true, uniqueness: true
    validates :block_height, :currency, :fee, :nonce, :receiver_address, :sender_address, :value, presence: true
  end