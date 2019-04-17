require 'dotenv'
require 'stripe'
require 'stripe_migrant'

Dotenv.load

target_key = ENV['STRIPE_NEW_SK']
source_key = ENV['STRIPE_OLD_SK']

migrator = StripeMigrant::Migrator.new(source_key: source_key, target_key: target_key)

# migrate customers
puts 'Migrating Customers'

customers = migrator.get_customers(api_key: source_key)
puts "customers retrieved: #{customers.count}"
migrator.update_customers(
  api_key: target_key,
  customers: customers,
  read_only: true
)
