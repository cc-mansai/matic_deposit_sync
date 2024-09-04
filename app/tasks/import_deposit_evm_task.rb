require 'net/http'
require 'json'
require 'uri'
require 'bigdecimal'
class ImportDepositEvmTask
  NODE_URL = 'https://go.getblock.io'.freeze
  def execute(since_block:, until_block:)
    (since_block..until_block).each do |block_number|
      puts "Fetching transactions for block number: #{block_number}"
      fetch_transactions(block_number)
    end
  end

  private

  # Fetches block information and transaction hashes
  def fetch_transactions(block_number)
    api_key = ENV['API_KEY']
    uri = URI("#{NODE_URL}/#{api_key}")
    headers = { 'Content-Type' => 'application/json' }
    block_hex = "0x#{block_number.to_s(16)}"
    # ブロック情報のリクエスト:
    # eth_getBlockByNumber: ブロック番号を16進数に変換してブロック情報を取得します。
    # params: [block_hex, true] の true を指定すると、トランザクションの詳細が含まれるレスポンスが取得できます。
    # 詳細は https://getblock.io/docs/matic/json-rpc/matic_eth_getblockbynumber/
    block_info_body = {
      jsonrpc: '2.0',
      method: 'eth_getBlockByNumber',
      params: [block_hex, true],
      id: 1
    }.to_json
    response = make_request(uri, block_info_body, headers)

    if response.nil? || response.code != '200'
      puts "Error fetching block info for block: #{block_number}"
      return
    end

    block_info = JSON.parse(response.body)['result']

    if block_info.nil?
      puts "No block info found for block: #{block_number}"
      return
    end

    fetch_transaction_details(block_info['transactions'], headers, uri, block_number)
  end

  # Fetches details for each transaction
  def fetch_transaction_details(transactions, headers, uri, block_number)
    # トランザクション情報のリクエスト:
    # eth_getTransactionByHash: 各トランザクションのハッシュを使って、その詳細情報を取得します。
    # 詳細は https://getblock.io/docs/matic/json-rpc/matic_eth_gettransactionbyhash/
    transactions.each do |tx_hash|
      body = {
        jsonrpc: '2.0',
        method: 'eth_getTransactionByHash',
        params: [tx_hash['hash']], # トランザクションのハッシュを直接指定
        id: 1
      }.to_json
      response = make_request(uri, body, headers)
      next if response.nil?
      handle_transaction_response(response, block_number)
    end
  end

  # Makes an HTTP POST request
  def make_request(uri, body, headers)
    response = Net::HTTP.post(uri, body, headers)
    puts "Request: #{body}"
    puts "Response code: #{response.code}"
    puts "Response body: #{response.body}"
    response.code == '200' ? response : nil
  rescue StandardError => e
    puts "HTTP Request Failed: #{e.message}"
    nil
  end

  # Handles the transaction response
  def handle_transaction_response(response, block_number)
    result = JSON.parse(response.body)['result']
    return unless result #resulがない場合コードの実行を止める

    EvmTransaction.create_with(
      block_height: block_number,
      currency: 'MATIC',
      fee: (result['gas'].to_i(16) * result['gasPrice'].to_i(16)).to_d / (10 ** 18), # (10 ** 18)はWeiの計算方法
      nonce: result['nonce'].to_i(16),
      receiver_address: result['to'],
      sender_address: result['from'],
      value: result['value'].to_d / (10 ** 18)
    ).find_or_create_by(txid: result['hash'])
  rescue JSON::ParserError => e
    puts "JSON Parsing Error: #{e.message}"
  end
end