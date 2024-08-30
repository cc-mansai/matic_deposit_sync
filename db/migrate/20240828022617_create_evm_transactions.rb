class CreateEvmTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :evm_transactions do |t|
      t.integer :block_height
      t.string :currency
      t.decimal :fee
      t.integer :nonce
      t.string :receiver_address
      t.string :sender_address
      t.string :txid
      t.decimal :value

      t.timestamps
    end
    add_index :evm_transactions, :txid, unique: true
  end
end
