require 'dotenv'
require 'stripe'
require 'stripe_migrant'

Dotenv.load

target_key = ENV['STRIPE_NEW_SK']
source_key = ENV['STRIPE_OLD_SK']

migrator = StripeMigrant::Migrator.new(source_key: source_key, target_key: target_key)

# migrate subscriptions
puts 'Migrating Subscriptions'

subs = migrator.migrate_subscriptions
puts "subs count: #{subs.count}"
results = migrator.cancel_confirmed_subscriptions
puts "deleted subs: #{results.count}"
