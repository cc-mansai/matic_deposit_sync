# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
- Ruby 3.1.4

* System dependencies
- Rails 6.1.7.8

* Configuration

1. Clone the repository:

git clone https://github.com/cc-mansai/matic_deposit_sync.git
cd matic_deposit_sync
2. Install required gems:
bundle install
3. Set up environment variables:
Create a .env file in the root directory of the project and add your API key:
API_KEY=your_getblock_api_key

* Database creation
rails db:create

* Database initialization
rails db:migrate

* Running the application
1. Start the Rails console:
bash
rails console
2. Use the ImportDepositEvmTask class to fetch transactions. For example, to fetch transactions in block range 61133859 to 61133859:
ruby
ImportDepositEvmTask.new.execute(since_block: 61133859, until_block: 61133860)

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
