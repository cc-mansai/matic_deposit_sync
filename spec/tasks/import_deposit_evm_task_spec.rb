require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ImportDepositEvmTask, type: :model do
  let(:task) { ImportDepositEvmTask.new }
  let(:api_key) { ENV['API_KEY'] || 'your_api_key' }

  before do
    allow(ENV).to receive(:[]).with('API_KEY').and_return(api_key)
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '#execute' do
    it 'fetches and saves transactions to the database' do
      stub_request(:post, "#{ImportDepositEvmTask::NODE_URL}/#{api_key}")
        .to_return(status: 200, body: { result: { transactions: [fake_tx_hash] } }.to_json, headers: {})

      stub_request(:post, "#{ImportDepositEvmTask::NODE_URL}/#{api_key}")
        .with(body: hash_including(method: 'eth_getTransactionByHash'))
        .to_return(status: 200, body: fake_tx_response, headers: {})

      expect {
        task.execute(since_block: 61133859, until_block: 61133859)
      }.to change(EvmTransaction, :count).by(1)
    end
  end

  describe '#fetch_transactions' do
    it 'handles nil block info' do
      stub_request(:post, "#{ImportDepositEvmTask::NODE_URL}/#{api_key}")
        .to_return(status: 200, body: { result: nil }.to_json, headers: {})

      expect {
        task.send(:fetch_transactions, 1234567)
      }.not_to change(EvmTransaction, :count)
    end
  end

  describe '#fetch_transaction_details' do
    it 'handles nil response' do
      allow(task).to receive(:make_request).and_return(nil)

      expect {
        task.send(:fetch_transaction_details, [fake_tx_hash], {}, URI('http://example.com'), 1234567)
      }.not_to change(EvmTransaction, :count)
    end
  end

  describe '#handle_transaction_response' do
    it 'creates or updates a transaction in the database' do
      response = instance_double(Net::HTTPResponse, code: '200', body: fake_tx_response)
      expect {
        task.send(:handle_transaction_response, response, 1234567)
      }.to change(EvmTransaction, :count).by(1)
    end

    it 'does not create duplicate transactions' do
      FactoryBot.create(:evm_transaction, txid: '0xtxid')
      response = instance_double(Net::HTTPResponse, code: '200', body: fake_tx_response)

      expect {
        task.send(:handle_transaction_response, response, 1234567)
      }.not_to change(EvmTransaction, :count)
    end
  end

  def fake_tx_hash
    { 'hash' => '0xtxid' }
  end

  def fake_tx_response
    {
      result: {
        hash: '0xtxid',
        gas: '0x5208',
        gasPrice: '0x4A817C800',
        nonce: '0x15',
        to: '0xreceiver',
        from: '0xsender',
        value: '0x1bc16d674ec80000'
      }
    }.to_json
  end
end